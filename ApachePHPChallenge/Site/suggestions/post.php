<?php

//
//get values 
//
$text = $_POST["suggestion"];
$email = $_POST['mail'];

if(!filter_var($email, FILTER_VALIDATE_EMAIL)){
    echo "<b> Not a real email</b>";
    return;
}


$db = pg_connect("host=localhost port=5432 dbname=webdb user=webserver password=Whatever");

//
//For safe SQL'ing
//
$escaped = str_replace(array('[',']',';','"','*','', "''", "\'", "'", "(", ")"), '', $text);  

$escaped = $text;

$query = "INSERT INTO web.suggestions (freeform, contact) VALUES ('$escaped', '$email')";

//
//Debug things
//
//echo $query;

echo "<b> Your suggestion:</b><ul></ul>";
echo $escaped; 
echo "<ul></ul> <b> has been noted</b>";


//insert the value
pg_query($db, $query);


?>