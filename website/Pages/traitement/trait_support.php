<?php
if (session_status() == PHP_SESSION_NONE) session_start(); # Pour démarrer la session

if (!isset($_SESSION['utilisateur'])) {
        if (session_status() == PHP_SESSION_NONE) session_start();
        $_SESSION['status'] = "primary";
        $_SESSION['message'] = "Vous devez être connecté, redirection sur la page de connexion...";
        header("Location: /Connexion");
        exit();
}

include('/home/Pages/configBDD/config.php');

$utilisateur_id = $_SESSION['utilisateur_id'];
$nom_utilisateur = $_SESSION['utilisateur'];

#On vérifie que l'utilisateur a bien saisi son adresse e-mail car elle est indispensable pour l'envoi de mail (même si déjà fait avant, comme ça, on vérif aussi qu'il n'a pas rentré l'URL comme ça

#$req_verif_email = "SELECT adresse_email FROM Utilisateur WHERE id = '$utilisateur_id'";
$req_verif_email = "SELECT adresse_email FROM Utilisateur WHERE id = '$utilisateur_id' AND adresse_email IS NOT NULL";

$resultat_verif_email = $connexion->query($req_verif_email);

if ($resultat_verif_email->num_rows == 0) {
    #La, l'utilisateur n'a pas renseigné son adresse e-mail donc on le redirige vers la page de profil
    $_SESSION['status'] = "warning";
    $_SESSION['message'] = "Vous devez renseigner votre adresse e-mail avant d'accéder à la FAQ.";
    header("Location: /trait_profil");
    exit();
}

?>

<!DOCTYPE html>
<html>

<head>
    <title>Contactez le support</title>
    <meta charset="utf-8">
    <link rel="stylesheet" href="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css">
    <script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
    <script src="https://maxcdn.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js"></script>
</head>

<body class="bg-light">
<?php include('/home/includes/header.php'); ?>
<div class="container mt-5">
    <h2>Contactez le support</h2><br/>
    <small>Assurez vous d'avoir correctement complété votre profil sur <a href="/trait_profil">cette page </a>sinon,
        l'envoi de mail ne se fera pas</small><br/>
    <br/><br/>
        <?php afficher_etat(); ?>
    <form action="/trait_envoi_mail" method="post">
        <div class="form-group">
            <label for="objet">Objet de la demande (maximum 90 caractères):</label>
            <input type="text" class="form-control" id="objet" name="objet" required maxlength="90"
                   oninput="updateCounter('objet', 'objetCounter', 90)">
            <p><span id="objetCounter">0</span></p>
        </div>

        <div class="form-group">
            <label for="body">Corps de la demande (maximum 250 caractères):</label>
            <textarea class="form-control" id="body" name="body" rows="4" required maxlength="250"
                      oninput="updateCounter('body', 'bodyCounter', 250)"></textarea>
            <p><span id="bodyCounter">0</span></p>
        </div>

        <button type="submit" class="btn btn-danger">Envoyer</button>
    </form>

    <!-- Script dont nous ne sommes pas l'auteur, plusieurs sources mais principalement : https://www.youtube.com/watch?v=yrmV6YqH2J4 nous a aidé-->

    <script>
        function updateCounter(inputId, counterId, maxLength) {
            const input = document.getElementById(inputId);
            const counter = document.getElementById(counterId);
            const currentLength = input.value.length;
            counter.textContent = currentLength + '/' + maxLength;
        }

    </script>
</div>
</body>
</html>

