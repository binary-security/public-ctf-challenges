<?php

//This needs admin permissions, so that it can insert the user
$email = strtolower($_POST['mail']);
$password = $_POST['Password'];
$rePassword =$_POST['rePassword'];


//
//check if actually email
//
if (!filter_var($email, FILTER_VALIDATE_EMAIL)){
    echo "<b>Not a real email<b>";
    return;
}

if ($password != $rePassword){
    echo "You have typed two different passwords";
    return;
}

//
//Least privilege here, to check that user is not already in the database
//

$db = pg_connect("host=localhost port=5432 dbname=webdb user=webserver password=Whatever");

$query = 'SELECT * FROM admin.get_user_status($1)';

$result = pg_query_params($db, $query, [$email]);
$row = pg_fetch_row($result);
if (strlen($row[0])!=0){
    echo "This email already has a user";
    return;
}

//
//Now we hash the pw and insert into users
//

$hashed = hash("sha256", $password, false);

//
//Arguments: 
//    email
//    pass
//    role
//

$query_user = 'SELECT admin.insert_user($1, $2)';
$query_pass = 'SELECT admin.insert_passwd($1, $2)';
$result = pg_query_params($db, $query_user, [$email, "user"]);
$result = pg_query_params($db, $query_pass, [$email, $hashed]);
echo "Creation Completed, go to <a href= '../login.html'> Login</a> to login"

?>