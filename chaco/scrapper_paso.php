<?php

function file_save($filename, $content) {
	$f = fopen($filename, "w");
	fwrite($f, $content);
	fclose($f);
}

function get_mesas() {
	$res = array();
	for($id=1; $id <= 69; $id++) {
		$cmd = "curl 'http://www.paso.electoralchaco.gov.ar/api/Mesas/mesasxmunicipio?municipioid=$id' -H 'Pragma: no-cache' -H 'Origin: http://www.paso.electoralchaco.gov.ar' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.8,es-419;q=0.6,es;q=0.4' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36' -H 'Content-Type: application/json' -H 'Accept: application/json, text/plain, */*' -H 'Cache-Control: no-cache' -H 'Referer: http://www.paso.electoralchaco.gov.ar/' -H 'Cookie: cookiesession1=5A501245MZDPMTD8REEWMDDCH2JF3570' -H 'Connection: keep-alive' --data-binary '{}' --compressed";
		$json = exec($cmd);
		$res[$id] = json_decode($json);
	}
	file_save("mesas.json", json_encode($res));
}

function get_resultados() {
	$cmd = function($muni, $mesa, $tipo) { return "curl 'http://www.paso.electoralchaco.gov.ar/api/VotosProvValidos/votos?municipioid=$muni&mesanumero=$mesa&tipo=$tipo' -H 'Pragma: no-cache' -H 'Origin: http://www.paso.electoralchaco.gov.ar' -H 'Accept-Encoding: gzip, deflate' -H 'Accept-Language: en-US,en;q=0.8,es-419;q=0.6,es;q=0.4' -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36' -H 'Content-Type: application/json' -H 'Accept: application/json, text/plain, */*' -H 'Cache-Control: no-cache' -H 'Referer: http://www.paso.electoralchaco.gov.ar/' -H 'Cookie: cookiesession1=5A501245MZDPMTD8REEWMDDCH2JF3570' -H 'Connection: keep-alive' --data-binary '{}' --compressed"; };
	$munis_mesas = json_decode(file_get_contents('mesas.json'));
	foreach ($munis_mesas as $muni => $mesas) {
		foreach ($mesas as $i => $mesa) {
			$mesa_id = explode('-', $mesa->mesa)[0];
			echo "\n$mesa->mesa\n";
			$json = exec($cmd($muni, $mesa_id, 'N'));
			$mesa->resultado = json_decode($json);
		}
	}
	file_save("resultados.json", json_encode($munis_mesas));
}

get_mesas();
get_resultados();

?>