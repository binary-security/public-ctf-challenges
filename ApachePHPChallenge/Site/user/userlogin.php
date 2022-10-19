<?php
//
//Login script, if someone (evilly) tries to login with the 
//wrong password we log it, using our state-of-the art logging
//capabilities. If it is correct, give them a thumbs up
//

$email = strtolower($_POST['mail']);
//
//check if actually email
//
if (!filter_var($email, FILTER_VALIDATE_EMAIL)){
    echo "<b>Not a real email<b>";
    return;
}

//
//Even we don't know the password
//
$passwordhash = hash("sha256", $_POST['Password']);

$db = pg_connect("host=localhost port=5432 dbname=webdb user=webserver password=Whatever");


//
//Returns a boolean whether we passed, which we display to users
//if false it has failed, so we log it
//We don't need to check for several rows, since create_user won't 
//make users with the same email
//
$query = 'SELECT * FROM admin.check_password($1, $2)';
$result = pg_query_params($db, $query, [$email, $passwordhash]);

$row = pg_fetch_row($result);

if ($row[0]!=1){
    //
    //No user, log it
    //

    //
    //We log the email, user-agent and ip. time is automatically added
    //
    $log_query = 'SELECT logs.write_failed_access($1,$2,$3)';
    $user_agent = $_SERVER["HTTP_USER_AGENT"];
    $ip = $_SERVER["REMOTE_ADDR"];
    $result = pg_query_params($db, $log_query, [$email, $user_agent, $ip]);
    echo "Login failed you sneak, this hack-attempt has been logged";
}
else{
    //
    //Succesfully logged in, tell the user what role he has
    //
    $query = 'SELECT * FROM admin.get_user_status($1)';

    $result = pg_query_params($db, $query, [$email]);
    $row = pg_fetch_row($result);
    echo "<h1> You have logged in!<h1>\n Your email ($email) has role  $row[0]";
}




?>