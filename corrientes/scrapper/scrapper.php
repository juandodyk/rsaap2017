<?php

function htmlenc($s, $enc = null) {
	if(!$enc) $enc = mb_detect_encoding($s);
	return mb_convert_encoding(trim($s), 'HTML-ENTITIES', $enc);
}
function str_before($str, $a) {
	$i = strpos($str, $a);
	if($i === false) return $str;
	return substr($str, 0, $i);
}
function google_cache($url) {
	return 'http://webcache.googleusercontent.com/search?q=cache:' . urlencode(str_before($url, '?'));
}
function post_context($post) {
	return stream_context_create(array(
		'http' => array(
			'method'  => 'POST',
			'content' => http_build_query($post)
		)
	));
}

class ScrapperNode {
	public $node, $html;
	function __construct($node, &$html) { $this->node = $node; $this->html =& $html; }
	function text() { return $this->node ? htmlenc($this->node->textContent) : ''; }
	function html() { return $this->node ? htmlenc($this->html->saveHTML($this->node)) : ''; }
	function attr($attr) { return $this->node ? htmlenc($this->node->getAttribute($attr)) : ''; }
}

class Scrapper {
	public $html, $xpath, $enc;
	
	//$params is a subset of array('xml', 'google_cache', 'silence', 'encoding', 'clean_aside', 'post')
	function __construct($url, $params = array()) {
		$xml = in_array('xml', $params);
		$gcache = in_array('google_cache', $params);
		if($gcache) $url = google_cache($url);
		$pre_t = microtime(true);
		$ctx = isset($params['post']) ? post_context($params['post']) : NULL;
		if(isset($params['ctx'])) $ctx = $params['ctx'];
		$source = file_get_contents($url, false, $ctx);
		$this->html = new DOMDocument();
		$this->enc = isset($params['encoding']) ? $params['encoding'] : 'utf-8';
		if(!$xml) @$this->html->loadhtml(htmlenc($source, $this->enc));
		else @$this->html->loadxml($source);
		$this->xpath = new DOMXpath($this->html);
		$this->clean(in_array('clean_aside', $params));
		if(!in_array('silence', $params))
			echo $url . " " . (microtime(true) - $pre_t) . "<br>\n";
	}
	
	function clean($aside = false) {
		$nodes = array();
		foreach($this->html->getElementsByTagname('script') as $node)
			$nodes[] = $node;
		if($aside) foreach($this->html->getElementsByTagname('aside') as $node)
			$nodes[] = $node;
		foreach($nodes as $node)
			$node->parentNode->removeChild($node);
	}
		
	function _query($query, $ctx = null) {
		if(!$this->xpath) return array();
		return !$ctx ? $this->xpath->query($query) :
				$this->xpath->query($query, $ctx);
	}
	
	function node($query, $ctx = null) {
		$node = $this->_query($query, $ctx);
		$node = $node ? $node->item(0) : null;
		return new ScrapperNode($node, $this->html, $this->enc);
	}
	
	function query($query, $ctx = null) {
		$nodes = array();
		foreach($this->_query($query, $ctx) as $node)
			$nodes[] = new ScrapperNode($node, $this->html, $this->enc);
		return $nodes;
	}
	
	function extract_articles($max_items=100) {
		$arts = array(); $count = 1;
		foreach($this->_query('//item') as $item) {
			$link = $this->node('link', $item)->text();
			$title = $this->node('title', $item)->text();
			$author = $this->node('author', $item)->text();
			if(!$author) @$author = $this->node('dc:creator', $item)->text();
			$description = $this->node('description', $item)->text();
			@$content = $this->node('content:encoded', $item)->text();
			$arts[$link] = new Article($link, $title, $author, $description.$content);
			if($count++ >= $max_items) break;
		}
		return $arts;
	}
}

?>