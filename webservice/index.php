<?php
####################################################################################
# index.php
# 
# Webservice de recolección de eventos a través de llamadas POST.
# Una vez recibidos, los reenvía a través de syslog.
#
####################################################################################

require_once('syslog.php');

########################################################
# MAIN
########################################################

# Inicializacion y configuracion del syslog
$syslog = new Syslog();
$syslog->SetServer('localhost');
$syslog->SetPort('514');
$syslog->SetProcess('JSON-to-Syslog');

# Se capturan los parametros del POST
$input = file_get_contents('php://input');

# Se separan los parametros en lineas
$json_array = explode ("\n",$input);

# Para depurar
$debuglog = fopen('debug.log', 'w');
$jsonlog = fopen('json.log', 'w');

# Cada linea se parsea y se manda por syslog
foreach ($json_array as $json)  {
        if (!empty($json)) {
		fwrite($jsonlog, $json);
		#$syslog_message = parse_json ( $json );
		$syslog_message = test_input ( $json );
		if ( $syslog_message ) {
			file_put_contents('salida.log', $syslog_message . "\n", FILE_APPEND);
			fwrite($debuglog, "Tamano linea: " . $syslog_message . "\n");
			$syslog->SetContent($syslog_message);
			$syslog->Send();
		}
	}
} 
	
fclose($debuglog);
fclose($jsonlog);

function test_input ( $json ) {
	$obj = json_decode($json);
	return $obj;
}

#########################################################
# parse_json
# 
# Funcion encargada de parsear el JSON de los parametros 
#  y devolver el mensaje con el formato de salida que se 
#  manda por syslog.
#
#########################################################
function parse_json ( $json ) {
	$obj = json_decode($json);
        $syslog_message = "";
	
        foreach ( $obj as $obj_element_key => $obj_element_value ) {
		if (is_object($obj_element_value)) {
			foreach ($obj_element_value as $obj_element_element_key => $obj_element_element_value) {
				$obj_element_element_key_urldecode = urldecode($obj_element_element_key);
                                $obj_element_element_value_urldecode = urldecode($obj_element_element_value);

                                if ($obj_element_element_key_urldecode == "warnData" || $obj_element_element_key_urldecode == "denyData") {
					$obj_element_element_value_urldecode_array = explode(";",$obj_element_element_value_urldecode);

					$syslog_message = $syslog_message . $obj_element_key . "_" . $obj_element_element_key_urldecode . "::";
                                        $array_size = count($obj_element_element_value_urldecode_array);
                                        $array_count = 1;

                                        foreach ($obj_element_element_value_urldecode_array as $obj_element_element_value_urldecode_array_value) {
						if ($array_size==$array_count) {
                                                	$syslog_message = $syslog_message . base64_decode($obj_element_element_value_urldecode_array_value);
                                                } else {
                                                        $syslog_message = $syslog_message . base64_decode($obj_element_element_value_urldecode_array_value) . ";";
                                                }

                                                $array_count++;
                                        }

                                	$syslog_message = $syslog_message . "||";
				} else {
                                	$syslog_message = $syslog_message . $obj_element_key . "_" . $obj_element_element_key_urldecode . "::" . $obj_element_element_value_urldecode;
                                        $syslog_message = $syslog_message . "||";
                                }
                        }
		} else {
			$syslog_message = $syslog_message . urldecode($obj_element_key) . "::" . urldecode($obj_element_value);
                        $syslog_message = $syslog_message . "||";
                }
	}

	return $syslog_message;
}
?>
