<?php

include_once('scrapper.php');

function read_table($t, $s) {
	$table = array();
	$columns = array();
	$first = true;
	foreach ($s->query('.//tr', $t->node) as $tr) {
		$row = array();
		foreach ($s->query('.//th', $tr->node) as $th) {
			$row[] = $th->text();
		}
		foreach ($s->query('.//td', $tr->node) as $th) {
			$row[] = $th->text();
		}
		if($first) {
			$columns = $row;
			$first = false;
		} else {
			$row_rich = array();
			for($i = 0; $i < count($row); $i++) {
				$row_rich[$columns[$i]] = $row[$i];
			}
			$table[] = $row_rich;
		}
	}
	return $table;
}

function file_save($filename, $content) {
	$f = fopen($filename, "w");
	fwrite($f, $content);
	fclose($f);
}

$url = "https://elecciones2017.corrientes.gov.ar/totmesa.php";
function ctx($mesa) {
	$content = "varmesa=$mesa"; $len = strlen($content);
	$header =
"Content-Length: $len
Pragma: no-cache
Cache-Control: no-cache
Origin: https://elecciones2017.corrientes.gov.ar
Upgrade-Insecure-Requests: 1
User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36
Content-Type: application/x-www-form-urlencoded
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8
Referer: https://elecciones2017.corrientes.gov.ar/totmesa.php
Accept-Encoding: gzip, deflate, br
Accept-Language: en-US,en;q=0.8,es-419;q=0.6,es;q=0.4";
	return stream_context_create(array(
		'http' => array(
			'method'  => 'POST',
			'header' => $header,
			'content' => $content
		)
	));
}

$N_MESAS = 798;
$resultados = array();
$alianzas_intendentes = array();
$alianzas_concejales = array();
for($mesa = 1; $mesa <= $N_MESAS; $mesa++) {
	$s = new Scrapper("compress.zlib://".$url, array('ctx' => ctx($mesa)));
	$t = $s->node('//table[@class="table"]');
	$resultados[$mesa] = read_table($t, $s);
	$ts = $s->query('//table[@class="table1"]');
	$alianzas_intendentes[$mesa] = read_table($ts[0], $s);
	$alianzas_concejales[$mesa] = read_table($ts[1], $s);
	//sleep(5);
}
file_save("resultados.json", json_encode($resultados));
file_save("alianzas_intendentes.json", json_encode($alianzas_intendentes));
file_save("alianzas_concejales.json", json_encode($alianzas_concejales));

?>