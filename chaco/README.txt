Resultados Elección Chaco 2017 para diputados provinciales.

Datos:
resultados.csv      Tabla con resultados por mesa
partidos.csv        Tabla con los ids de los partidos y sus nombres
deptos.json         Geometría de Departamentos
municipios.json     Geometría de Municipios
circuitos.json      Geometría de Circuitos
municipios.csv      Tabla con ID, Nombre de municipios

Scripts:
analisis.R          Código R en el que corro los mixed models
test.R              Código R en el que pruebo modelos hechos con Stan
chaco2017paso.ipynb Notebook de Jupyter que cuenta el procedimiento y procesa los datos
scrapper.php        Scrapper en PHP. Baja las mesas de cada municipio y sus resultados

Extras:
mesas.json          JSON con mesas por municipio, producido por el scrapper
resultados.json     JSON con resultados por mesa, producido por el scrapper
tabula.csv          Tabla con electores por circuito, producida por TabulaPDF
resultados_agregados.json JSON con resultados por circuito; incluye turnout
model_*.stan        Código Stan de los modelos que pruebo en test.R

