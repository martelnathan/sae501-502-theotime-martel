<!--Source du code : https://www.journaldunet.com/developpeur/tutoriel/php/060531-php-fputcsv.shtml->

<?php

if (session_status() == PHP_SESSION_NONE) session_start();

if (!isset($_SESSION['utilisateur'])) {
        if (session_status() == PHP_SESSION_NONE) session_start();
        $_SESSION['status'] = "primary";
        $_SESSION['message'] = "Vous devez être connecté, redirection sur la page de connexion...";
        header("Location: /Connexion");
        exit();
}

#On récupère les données des comparaisons qu'on avait stocké dans la session de l'utilisateur

$comparaison1 = isset($_SESSION['comparaison1']) ? $_SESSION['comparaison1'] : '';
$comparaison2 = isset($_SESSION['comparaison2']) ? $_SESSION['comparaison2'] : '';

#On récupère aussi les attributs fusionnés qu'on avait stocké dans la session de l'utilisateur

$attributs_fusionnes = $_SESSION['attributs_fusionnes'];

#Ensuite, on génère le contenu CSV :

$donnees = "Attributs, $comparaison1, $comparaison2\n";
foreach ($attributs_fusionnes as $attribut => $valeurs) {

        #$val1 = traitement(simplify($attribut), $valeurs[0]) : '';
        #$val2 = traitement(simplify($attribut), $valeurs[1]) : '';

        $val1 = isset($valeurs[0]) ? traitement(simplify($attribut), $valeurs[0]) : '';
        $val2 = isset($valeurs[1]) ? traitement(simplify($attribut), $valeurs[1]) : '';

        $donnees .= "$attribut, $val1, $val2\n"; #Ajoute la ligne dans le fichier
}

$nomfichier = 'resultat_comparaisons_' . $comparaison1 . '_' . $comparaison2 . '.csv';

#Là on force le téléchargement

header('Content-Type: text/csv');
header('Content-Disposition: attachment; filename="' . $nomfichier . '"');

$utilisateur = $_SESSION['utilisateur'];
$logs = date('Y-m-d H:i:s') . " - [INFO] - L'utilisateur " . $utilisateur . " vient de télécharger sa comparaison entre $comparaison1 et $comparaison2.";
shell_exec('echo "' . $logs . '" >> /home/logs/logs.txt');

#On écrit le contenu qui a été généré
echo $donnees;
exit();

function traitement($attribut, $valeur)
{
        # fonction pour filtrer l'affichage et le rendre plus propre
        $banned_attributs = array(
                'couleurboîte', 'couleurécriture' , 'couleurcadre', 'titreblanc', 'logo', 'taillelogo', 'nometlogo', 'nomidentifiant', 'taille', 'espace', 'tailledrapeau');
        $banned_attributs_regex = array(
                '/(pattern_...)/', '/(pattern_..)/', '/(socks.)/'
        );
        $banned_caracters = array('Langue|en|texte=', '[', ']', '{', '}', '|', 'url=', 'URL');
        $banned_caracters_regex = array(
                '/(...-d)/', '/(\(.+\))/'
        );

        foreach ($banned_attributs as $test) {
                if ($test == $attribut) {
                        return "";
                }
        }

        foreach ($banned_attributs_regex as $regex){
                if (preg_replace($regex, '', $attribut) == "") {
                        return "";
                }
        }


        if (preg_replace('/\s+/', '', $valeur) == "") {
                $valeur = '';
        }

        foreach ($banned_caracters as $modification) {
                $valeur = str_replace($modification, '', $valeur);
        }

        foreach ($banned_caracters_regex as $regex){
                $valeur = preg_replace($regex, '', $valeur);
        }

        return $valeur;
}

function simplify($attribut)
{
        $attribut = str_replace(' ', '', $attribut);
        return $attribut;
}

?>
