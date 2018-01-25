library(lme4)
library(ggplot2)
library(grid)
setwd("~/projects/datos/rsaap2017/corrientes")

df = read.csv('todo.csv')
n = ncol(df)
df$voto_cruzado_espejo = df$voto_cruzado / df$Total.Votos.Válidos.1.Intendente.Vice
df$voto_cruzado_revisado_prop = df$voto_cruzado_revisado / df$Total.Votos.Válidos.1.Intendente.Vice
df$fpv = df$Frente.Para.la.Victoria..201..1.Alianzas.Intendente.Vice / df$Total.Votos.Válidos.1.Intendente.Vice
df$eco = df$Encuentro.por.Corrientes.ECO.Cambiemos..203..1.Alianzas.Intendente.Vice / df$Total.Votos.Válidos.1.Intendente.Vice
df$hc = df$Haciendo.Corrientes..205..1.Alianzas.Intendente.Vice / df$Total.Votos.Válidos.1.Intendente.Vice
df$ni = df$Votos.Generales.1.Intendente.Vice
df$blanco = df$VOTOS.en.Blanco.1.Intendente.Vice / df$Votos.Generales.1.Intendente.Vice
df$blanco_concejales = df$VOTOS.en.Blanco.2.Concejales / df$Votos.Generales.2.Concejales
df$nulo = df$VOTOS.Nulos.1.Intendente.Vice / df$Votos.Generales.1.Intendente.Vice
df$nulo_concejales = df$VOTOS.Nulos.2.Concejales / df$Votos.Generales.2.Concejales
df$nulos = df$VOTOS.Nulos.1.Intendente.Vice+df$VOTOS..Recurridos.1.Intendente.Vice+df$VOTOS.de.Identidad.Impugnada.1.Intendente.Vice
df$nulos = df$nulos/df$Votos.Generales.1.Intendente.Vice
df$noafir = df$Votos.Generales.1.Intendente.Vice-df$Total.Votos.Válidos.1.Intendente.Vice
df$noafir = df$noafir / df$Votos.Generales.1.Intendente.Vice
df[,n:ncol(df)] = 100*df[,n:ncol(df)]

# Me quedo sólo con los circuitos donde hubo BUE
restrict = function(df) {
  df = df[df$Circuito %in% c('3 -- CAPITAL', '5B -- CAPITAL'), ]
  df['Circuito'] <- lapply(df['Circuito'], as.character)
  return(df)
}

ols_ci = function(df, out, circ) {
  df = df[df$Circuito == circ, ]
  f = paste(out, "~", "bue")
  fm = lm(f, df[df$Circuito == circ, ])
  #print(summary(fm))
  c = fm$coefficients['bue']
  ci = confint(fm)['bue', ]
  return(c(c, ci[1], ci[2]))
}

# Sacar los intervalos de confianza de las mean-differences en cada cirtuito
fm = function() {
  df = df[1:377,]
  df = restrict(df)
  res = data.frame()
  outs = c('hc', 'eco', 'fpv', 'blanco', 'nulos', 'noafir', 'voto_cruzado_espejo', 'voto_cruzado_revisado_prop')
  circs = unique(df$Circuito)
  for(out in outs) {
    row = c()
    for(circ in circs) {
      row = c(row, ols_ci(df, out, circ))
    }
    res = rbind(res, row)
  }
  tick = c("Haciendo Corrientes", "ECO-Cambiemos", "Frente para la Victoria",
           "Voto en blanco", "Votos nulos", "Votos no afirmativos",
           "Voto cruzado entre listas", "Voto cruzado entre alianzas")
  res = cbind(tick, res)
  params = c("Circuito 3", "Circuito 5B")
  names = c('tick')
  for(param in params) {
    names = c(names, param, paste(param,'min',sep=''), paste(param,'max',sep=''))
  }
  print(names)
  colnames(res)=names
  PlotCIs(res, params)
}

# Gráfico de los intervalos de confianza. Recibe un dataframe con el ticker y los alpha, alphamin, alphamax, etc
PlotCIs <- function(df, params) {
  df = df[nrow(df):1, ]
  yline = c(0, 0); n = length(params)
  grid.newpage()
  pushViewport(viewport(layout = grid.layout(1, n)))
  vplayout <- function(x, y) viewport(layout.pos.row = x, layout.pos.col = y)
  df$tick <- as.character(df$tick)
  df$tick <- factor(df$tick, levels=unique(df$tick))
  for(i in 1:n) {
    param <- params[i]
    print(df[[param]])
    print(df[[paste0(param,"min")]])
    print(df[[paste0(param,"max")]])
    p <- ggplot(df, aes(x=tick, y=df[[param]], ymin=df[[paste0(param,"min")]], ymax=df[[paste0(param,"max")]])) +
      geom_pointrange() + geom_hline(yintercept = yline[i], linetype = "dotted") + theme_bw() + coord_flip() + ylab(param) + xlab("") + ylim(c(-9,9))
    
    print(p, vp = vplayout(1, i))
  }
}

# El resultado de la elección a intendente si cambio las mesas con BUE
# por un promedio de las mesas de su circuito que no tuvieron BUE
fc = function() {
  cs = 89:95
  s = colSums(df[df$bue == 0, cs])
  circs = c('3 -- CAPITAL', '5B -- CAPITAL')
  for(circ in circs) {
    n = nrow(df[df$bue == 1 & df$Circuito == circ, ])
    dfc = df[df$bue == 0 & df$Circuito == circ, cs]
    s = s + n*colSums(dfc)/nrow(dfc)
  }
  ret = c()
  tot = s['Total.Votos.Válidos.1.Intendente.Vice']
  ret['fpv'] = s['Frente.Para.la.Victoria..201..1.Alianzas.Intendente.Vice'] / tot
  ret['eco'] = s['Encuentro.por.Corrientes.ECO.Cambiemos..203..1.Alianzas.Intendente.Vice'] / tot
  ret['hc'] = s['Haciendo.Corrientes..205..1.Alianzas.Intendente.Vice'] / tot
  return(ret)
}
