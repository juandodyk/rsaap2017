library(lme4)
library(ggplot2); theme_set(theme_bw())
library(grid)
library("rstan")
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())
setwd("~/projects/datos/rsaap2017/chaco")
# rm(list = ls())

# Cargo los datos
circs = c('16A', '62', '104', '119', '88', '13A', '136', '98', '117', '78', '8A', '22A')
paso = read.csv("resultados_paso.csv", as.is=T)
gen = read.csv("resultados.csv", as.is=T)
res = merge(paso, gen, by=c("mesa", "circuito", "municipio", "femenina", "municipio_nombre", "electronica"))
res = res[res$cargada.x*res$cargada.y==1, ]
res = res[res$totales.x>=5 & res$totales.y>=5, ]
res = res[res$circuito %in% circs, ]
partidos = read.csv("partidos.csv", as.is=T)
partidos_paso = read.csv("partidos_paso.csv", as.is=T)

# Boxplots de votos al FCHMM en las generales por circuito, en mesas sin SEV y con SEV
res$elecirc = paste0(res$circuito, ".", res$electronica)
plot(factor(res$elecirc), res$G652/res$totales.y*100, col=c("white", "red"), pch=20)

# Genero algunas columnas más
res$nulos.x = res$nulos.x + res$recurridos
res$nulos.y = res$nulos.y + res$recur
res$vc = 0
for(p in partidos$PartidoID) {
  res[, paste0("D", p)] = 100 * abs(res[, paste0("G", p)]/res$totales.y - res[, paste0("P", p)]/res$totales.x)
  res$vc = res$vc + res[, paste0("D", p)]
}
res$Dblanco = 100 * abs(res$blanco.y/res$totales.y - res$blanco.x/res$totales.x)
res$Dnulos = 100 * abs(res$nulos.y/res$totales.y - res$nulos.x/res$totales.x)
res$Dnopositivos = 100 * abs(res$validos.y/res$totales.y - res$validos.x/res$totales.x)
ps = paste0("P", unique(partidos_paso$PartidoID))
res$PNEP = rowSums(res[,ps])^2/rowSums(res[,ps]^2)
ps = paste0("P652.", 1:11)
res$P652NEP = rowSums(res[,ps])^2/rowSums(res[,ps]^2)
ps = paste0("P653.", 1:3)
res$P653NEP = rowSums(res[,ps])^2/rowSums(res[,ps]^2)
ps = paste0("G", partidos$PartidoID)
res$GNEP = rowSums(res[,ps])^2/rowSums(res[,ps]^2)

# Código para producir cada gráfico
graficar = function(params, labels, ylabel) {
  cis = c()
  for(i in 1:length(params)) {
    f = paste0(params[i], "~circuito+electronica+(0+electronica|circuito)")
    m = lmer(f, data=res)#, REML = F)
    b = fixef(m)['electronica']
    ci = confint(m, method="Wald")
    cis = rbind(cis, c(b, ci['electronica',]))
  }
  ls = factor(labels, levels=rev(labels))
  cis = data.frame(partido=ls, coef=cis[,1], l=cis[,2], u=cis[,3])
  p <- ggplot(cis, aes(x=partido, y=coef, ymin=l, ymax=u)) +
    geom_pointrange() + geom_hline(yintercept = 0, linetype = "dotted") +
    theme_bw() + coord_flip() + ylab(ylabel) + xlab("") #+ ylim(c(-15,15))
  return(p)
}

# Código para hacer el gráfico "analisis_chaco"
plotcis = function() {
  vds = list("1" = list(
    params = c("I(P652/totales.x*100)", "I(P653/totales.x*100)", "I(P71/totales.x*100)",
               "I((validos.x-P652-P653-P71)/totales.x*100)", "I(blanco.x/totales.x*100)",
               "I(nulos.x/totales.x*100)", "I((1-validos.x/totales.x)*100)"),
    labels = c("FCHMM", "Cambiemos", "PO",
               "Otros", "Blanco", "Nulos", "No afirmativos"),
    main = "PASO"
  ),
  "2" = list(
    params = c("I(G652/totales.y*100)", "I(G653/totales.y*100)", "I(G71/totales.y*100)",
               "I((validos.y-G652-G653-G71)/totales.y*100)", "I(blanco.y/totales.y*100)",
               "I(nulos.y/totales.y*100)", "I((1-validos.y/totales.y)*100)"),
    labels = c("FCHMM", "Cambiemos", "PO",
               "Otros", "Blanco", "Nulos", "No afirmativos"),
    main = "Elecciones legislativas"
  ),
  "3" = list(
    params = c("D652", "D653", "D71", "I(vc-D652-D653-D71)", "Dblanco", "Dnulos", "Dnopositivos"),
    labels = c("FCHMM", "Cambiemos", "PO",
               "Otros", "Blanco", "Nulos", "No afirmativos"),
    main = "Diferencia"
  ))
  n = length(vds)
  grid.newpage()
  pushViewport(viewport(layout = grid.layout(1, n)))
  vplayout <- function(x, y) viewport(layout.pos.row = x, layout.pos.col = y)
  for(i in as.character(1:n)) {
    print(graficar(vds[[i]]$params, vds[[i]]$labels, vds[[i]]$main), vp = vplayout(1, i))
  }
}

# Función que transforma votos en bancas según D'Hondt
dHondt <- function(seats, votes) {
  fracs = votes
  ret = rep(0, length(votes))
  names(ret) = names(votes)
  for(i in 1:seats) {
    w = which.max(fracs)
    ret[w] = ret[w] + 1
    fracs[w] = votes[w]/(ret[w] + 1)
  }
  return(ret)
}
dHondt(16, colSums(gen[,paste0("G", partidos$PartidoID)]))

# Simulo qué hubiera pasado si no había voto electrónico
simulacion = function() {
  # Fiteo el modelo
  res_ = gen[gen$circuito %in% circs & gen$totales > 0, ]
  ps = c("G652", "G653", "G71")
  data = list(Mesas = nrow(res_),
              Circuitos = length(unique(res_$circuito)),
              Partidos = length(ps),
              votos = res_[, ps] / res_$totales,
              circuito = as.numeric(factor(res_$circuito)),
              electronica = res_$electronica)
  fit = stan(file = 'modelo.stan', data = data, iter=10000, chains=4,
             pars=c("beta", "b", "b_"))
  bs = as.data.frame(fit)
  
  # Tabla de resultados simulados
  sim = array(0, dim=c(nrow(bs), length(unique(gen$circuito)), length(ps)))
  dimnames(sim)[[2]] = unique(gen$circuito)
  dimnames(sim)[[3]] = ps
  
  # Simulo los circuitos con voto electronico parcial
  for(circ in circs) {
    i = match(circ, levels(factor(res_$circuito)))
    tmp = res_[res_$circuito == circ, ]
    for(k in 1:length(ps)) {
      p = ps[k]
      sim[, circ, p] = sapply(1:nrow(bs),
                              function(s) sum(tmp[, p] - bs[s, paste0('b[',i,',',k,']')] * tmp$electronica * tmp$totales))
    }
  }
  
  # Simulo los circuitos con voto electronico total
  ce = table(gen$circuito, gen$electronica)
  circs_electronica = rownames(ce[ce[, "0"] == 0, ])
  for(circ in circs_electronica) {
    tmp = gen[gen$circuito == circ, ]
    for(k in 1:length(ps)) {
      p = ps[k]
      sim[, circ, p] = sapply(1:nrow(bs),
                              function(s) sum(tmp[, p] - bs[s, paste0('b_[',k,']')] * tmp$totales))
    }
  }
  
  # Dejo los resultados de los circuitos sin voto electrónico
  circs_no_electronica = rownames(ce[ce[, "1"] == 0, ])
  for(circ in circs_no_electronica) {
    tmp = gen[gen$circuito == circ, ]
    for(p in ps)
      sim[, circ, p] = sum(tmp[, p])
  }
  
  # Obtengo las bancas de cada simulación
  resultados = t(apply(sim, 1, function(s) dHondt(16, colSums(s))))
  
  resultados
}


#################################################################################
# Cosas extra
#################################################################################

# Quiero ver si electronica tiene un efecto sobre la varianza (respuesta: no)
prueba = function() {
  m = lmer(I(G652/totales.y*100)~circuito+electronica+(electronica|circuito), res)
  summary(lm(log(resid(m)^2)~res$electronica))
}

# Extraigo los datos de mesas de Chaco en las PASO legislativas
mesas_paso = function() {
  mesas = read.csv("~/projects/datos/paso2017/arg/MesasDNacionales.csv", as.is=T)
  mesas = mesas[mesas$mes_proCodigoProvincia==6,]
  mesas$mesCodigoCircuito = trimws(mesas$mesCodigoCircuito)
  mesas$mesCodigoCircuito = sub("^0*", "", mesas$mesCodigoCircuito)
  mesas = mesas[mesas$mesCodigoCircuito %in% circs, ]
}

# Extraigo la cantidad de electores de cada circuito
ftabula = function() {
  tabula = read.csv("tabula.csv", as.is=T, header=F)
  tabula = tabula[, c(2, 4:7)]
  tabula$V2 = sub(" ", "", tabula$V2)
  tabula = tabula[tabula$V2 %in% circs, ]
  tabula$m = as.numeric(ifelse(tabula$V4 != "", tabula$V4, tabula$V5))
  tabula$f = as.numeric(ifelse(tabula$V6 != "", tabula$V6, tabula$V7))
  tabula = tabula[, c("V2", "m", "f")]
  tabula$t = tabula$m + tabula$m
  rownames(tabula) = tabula$V2
  tabula = tabula[circs, ]
  tabula$tp = apply(tabula, 1, function(x) sum(res$totales.x[res$circuito==x[1]]))
  tabula$tg = apply(tabula, 1, function(x) sum(res$totales.y[res$circuito==x[1]]))
  boxplot(list(paso=tabula$tp/tabula$t, general=tabula$tg/tabula$t), main="Participacion")
}
