#=====================================================================#
#		      	Devoir #3 - IFT1227		       		# 	
# Date: 2020-04-09							#
#									#
# But: Programme réalisé dans le cadre du cours IFT1227		#	
#									#
# Auteures: Elise ZHENG (20148416) - elise.zheng@umontreal.ca		#
# 	    Yuyin DING (20125263) - yuyin.ding@umontreal.ca		#      	
#                                                             		#
# Descriptif: Ce programme permet à l'utilisateur d'entrer un texte,	#
# puis retourne chaque mot du texte non trié (dans l'ordre dans	#
# lequel il a été entré) puis trié par ordre alphabétique.		#
#=====================================================================#

# segment de la mémoire contenant les données globales
.data
# tampon réservé pour le texte
buffer:  .space    300
tabMots: .space    600

# messages à afficher
msg1: 	    .asciiz   "Vous avez saisi le texte suivant:\n"
msg2:       .asciiz   "\nTableau de mots non trié:\n"
msg3:       .asciiz   "\nTableau de mots trié:\n"
saut:       .asciiz   "\n"
msgErreur:  .asciiz   "Votre texte dépasse les 300 caractères!"

#==========================================
# segment de la mémoire contenant le code
.text
main:
	jal saisir			# demande input
	
	addi $s0, $v0, -2		# $s0 = taille - 2
	sb   $0, buffer($s0)		# coupe le texte pour ne pas compter les 2 \n
	bge  $s0, 300, erreur		# erreur si texte trop grand (les sauts interlignes sont comptés)
	
	la   $a0, msg1			# imprime "Vous avez saisi le texte suivant:"
	li   $v0, 4
	syscall
	
	la   $a0, buffer		# imprime texte entré
	li   $v0, 4
	syscall
	
	la   $a0, buffer		# $a0 = texte
	move $a1, $s0			# $a1 = taille
	jal  decMots			# découpe les mots saisis
	
	la   $a0, msg2			# imprime "Tableau de mots non trié:"
	li   $v0, 4
	syscall
	
	la   $a0, tabMots		# $a0 = tabMots
	move $a1, $v1			# $a1 = taille
	jal  afficher			# affiche mots non triés
	
	la   $a0, tabMots		# $a0 = tabMots
	move $a1, $v1			# $a1 = taille
	jal  trier			# trie mots
	
	la   $a0, msg3			# imprime "Tableau de mots trié:"
	li   $v0, 4
	syscall
	
	la   $a0, tabMots		# $a0 = tabMots
	move $a1, $v1			# $a1 = taille
	jal  afficher			# affiche mots triés

exit:
	li   $v0, 10			# termine le programme
	syscall

erreur:
	la   $a0, msgErreur		# imprime msg d'erreur
	li   $v0, 4
	syscall
	j    exit


# ------------------------------------
# fonction saisir: permet de saisir du texte et s'arrête lorsqu'une ligne vide est entrée
# retourne: $v0 taille du txt en nb octets (nb de caracteres)
saisir:
	addi $sp, $sp, -4 		# alloue de l'espace
	sw   $ra, 0($sp)		# sauve adresse de retour
	
	la   $a0, buffer		# adresse
	li   $a1, 301			# nombre de caractères à lire + 1
	li   $v0, 8			# demande input ligne
	syscall
	
	jal  getSize			# $v0 = taille du texte
	
whileSaisir:
	add  $a0, $a0, $v0		# adresse pour la nouvelle ligne
	li   $v0, 8			# demande input ligne
	syscall

	jal  getSize			# taille de la nouvelle ligne
	beq  $v0, 1, doneSaisir		# ligne entrée est vide -> fin

	j    whileSaisir

doneSaisir:
	la   $a0, buffer
	jal  getSize			# retourne la taille du texte
	lw   $ra, 0($sp)		# récupère adresse de retour
	addi $sp, $sp, 4		# désalloue l'espace
	jr   $ra

# ------------------------------------
# fonction getSize: retourne la taille du texte à partir d'une adresse entrée
# param: $a0 adresse de début du texte
# retourne: $v0 taille
getSize:
	li   $s0, 0			# int i = 0
	la   $t0, ($a0)			# charge adresse dans une variable tmp

whileSize:
	lb   $t1, 0($t0)		# charge caractère (1car = 1byte)
	beqz $t1, doneSize		# plus de caractère -> fin du texte
	addi $s0, $s0, 1		# i++
	addi $t0, $t0, 1		# adresse du caractère suivant
	j    whileSize

doneSize:
	move $v0, $s0			# retourne taille
	jr   $ra
	

# ------------------------------------
# fonction lettre : retourne true si car est une lettre, false sinon
# param: $a0 car
# retourne: $v0 boolean
lettre:
	blt  $a0, 65, falseLettre	# 0 <= car <= 65 -> false
	blt  $a0, 90, trueLettre	# 65 <= car <= 90 -> true
	blt  $a0, 97, falseLettre	# 90 <= car <= 97 -> false
	blt  $a0, 122, trueLettre	# 97 <= car <= 122 -> true
 		
falseLettre:
	li   $v0, 0
	jr   $ra

trueLettre:
	li   $v0, 1
	jr   $ra


# ------------------------------------
# fonction decMots: découpe le texte en mots
# param: $a0 texte, $a1 taille
# retourne: $v0 tabMots, $v1 nbElem
decMots:
	addi $sp, $sp, -4 		# alloue de l'espace
	sw   $ra, 0($sp)		# sauve l'adresse de retour
	li   $v1, 0			# $v1 = nbElem
	move $s0, $a0			# i = adresse buffer
	add  $a1, $a1, $a0		# taille = taille + adresse buffer

forDecMots:
	bge  $s0, $a1, doneDecMots	# while i < taille
	lb   $a0, ($s0)			# load premier caractère
	
whileNonLetter:
	jal  lettre
	bnez $v0, suite1		# pas une lettre -> sort de la boucle
	addi $s0, $s0, 1		# i++
	lb   $a0, ($s0)			# load prochain caractère
	bge  $s0, $a1, doneDecMots	# i > taille -> fin
	j    whileNonLetter

suite1:
	sll  $t1, $v1, 2		# $t1 = nbElem * 4
	sw   $s0, tabMots($t1)		# met l'adresse du début du mot dans tabMots

whileLetter:
	jal  lettre
	addi $s0, $s0, 1		# i++
	lb   $a0, ($s0)			# load prochain caractère
	bnez $v0, whileLetter		# une lettre -> continu

	addi $v1, $v1, 1		# nbElem++
	j    forDecMots

doneDecMots:
	la   $v0, tabMots
	lw   $ra, 0($sp)		# remet l'adresse de retour
	addi $sp, $sp, 4		# désalloue l'espace
	jr   $ra
	
# ------------------------------------
# fonction strCmp : compare str1 et str2, retourne true si str1 <= str2, false sinon
# param: $a0 str1, $a1 str2
# retourne: $v0 boolean
strCmp:
	addi $sp, $sp, -4 		# alloue de l'espace
	sw   $ra, 0($sp)		# sauve l'adresse de retour
	li   $s7, 0			# i = 0
	move $t8, $a0			# $t8 = str1
	move $t9, $a1			# $t9 = str2

whileCmp:
	lb  $a2, ($t8)			# load car
	lb  $a3, ($t9)			# load car

	blt $a2, $a3, trueCmp		# str1 < str2 -> true
	bgt $a2, $a3, falseCmp 		# str1 > str2 -> false

	addi $t8, $t8, 1		# sinon on compare les prochains car
	addi $t9, $t9, 1
	
	beqz $a2, trueCmp		# fin du str1 -> true
	beqz $a3, falseCmp		# fin du str2 -> false
	
	j    whileCmp

trueCmp:
	li   $v0, 1
	j    doneCmp

falseCmp:
	li   $v0, 0

doneCmp:
	lw   $ra, 0($sp)		# restaure l'adresse de retour
	addi $sp, $sp, 4		# désalloue l'espace
	jr   $ra

# ------------------------------------
# fonction trier: trie alphabétiquement tabMots avec un bubble sort
# param: $a0 tabMots, $a1 taille
trier:
	addi $sp, $sp, -4 		# alloue de l'espace
	sw   $ra, 0($sp)		# sauve adresse de retour
	li   $t0, 0			# i = 0
	addi $s0, $a1, -1		# $s0 = taille - 1
	move $s2, $a0
	j    debutTri
for1:
	addi $t0, $t0, 1		# i++
debutTri:
	bge  $t0, $s0, doneTri		# while i < taille - 1
	li   $t1, 0			# j = 0
	sub  $s1, $s0, $t0 		# taille - 1 - i
		
for2:
	bge  $t1, $s1 , for1		# while j < taille - 1 - i
	sll  $t4, $t1, 2		# $t4 = j*4
	add  $a0, $t4, $s2		
	addi $a1, $a0, 4		
	lw   $a0, ($a0)			# $a0 = tabMots[j]
	lw   $a1, ($a1)			# $a1 = tabMots[j+1]
	jal  strCmp
	addi $t1, $t1, 1		# j++
	bnez $v0, for2			# si dans le bon ordre, on saute

	# swap
	add  $a0, $t4, $s2
	addi $a1, $a0, 4
	lw   $t4, ($a0)			# $t4 = tabMots[j]
	lw   $t5, ($a1)			# $t5 = tabMots[j+1]
	sw   $t4, ($a1)			# tabMots[j] = tabMots[j+1]
	sw   $t5, ($a0)			# tabMots[j+1] = tabMots[j]
	j for2

doneTri:
	lw   $ra, 0($sp)		# récupère adresse de retour
	addi $sp, $sp, 4		# désalloue l'espace
	jr   $ra
	

# ------------------------------------
# fonction tailleMax: retourne taille du plus long mot dans tabMots
# param: $a0 tabMots, $a1 taille
# retourne: $v0 max
tailleMax:
	addi $sp, $sp, -4 		# alloue de l'espace
	sw   $ra, 0($sp)		# sauve adresse de retour

	li   $s0, 0			# max = 0
	li   $s1, 0			# i = 0
	move $s5, $a0			# tabMots
	move $t3, $a1			# taille (nomre de mots)
	
forTM:
	bge  $s1, $t3, doneTM		# i >= taille -> fin
	sll  $t7, $s1, 2		# i * 4
	add  $t7, $s5, $t7
	lw   $t7, ($t7)			# load le mot i
	li   $t5, 0			# tmp = 0

whileTM:
	add  $a0, $t5, $t7
	lb   $a0, ($a0)			# load lettre suivante
	jal  lettre
	beqz $v0, ifTM	 		# pas une lettre -> sort de la boucle
	addi $t5, $t5, 1		# tmp++
	j    whileTM

ifTM:
	slt  $t7, $s0, $t5		# max < tmp ?
	beqz $t7, skipTM		# si non, skip
	move $s0, $t5			# max = tmp
skipTM:
	addi $s1, $s1, 1		# i++ (mot suivant)
	j    forTM	        

doneTM:
	move $v0, $s0			# retourne max
	lw   $ra, 0($sp)		# récupère adresse de retour
	addi $sp, $sp, 4		# désalloue l'espace
	jr   $ra


# ------------------------------------
# fonction afficher: affiche chaque mots de tabMots 4 par 4 et alignés
# param: $a0 tabMots, $a1 taille
afficher:
	addi $sp, $sp, -4 		# alloue de l'espace
	sw   $ra, 0($sp)		# sauve adresse de retour
	move $s4, $a0			# $s4 = tabMots
	jal  tailleMax
	move $s0, $v0			# $s0 = tailleMax
	li   $s1, 0			# i = 0

forAff:
	bge  $s1, $a1, doneAff		# dernier mot -> fin
	sll  $t0, $s1, 2
	add  $s3, $s4, $t0
	lw   $s3, ($s3)			# adresse du mot i
	
# print chaque lettre du mot i
	li   $s2, 0			# j = 0
while1:
	add  $a0, $s2, $s3
	lb   $a0, ($a0)			# lettre suivante
	jal  lettre
	beqz $v0, while2		# pas une lettre -> fini d'imprimer le mot, sort de la boucle
	
	li   $v0, 11			# imprime la lettre
	syscall
	
	addi $s2, $s2, 1		# j++
	j while1

# ajoute du padding
while2:
	bgt  $s2, $s0, ifAff		# j > max -> assez de padding, sort de la boucle
	li   $a0, ' '
	li   $v0, 11			# ajoute padding
	syscall
	addi $s2, $s2, 1		# j++
	j while2
	
# saute une ligne tous les 4 mots
ifAff:
	addi $t0, $s1, 1 		# taille + 1
	beq  $t0, $a1, doneIf 		# dernière ligne -> fin
	li   $t1, 4			# $t1 = 4
	div  $t0, $t1			# (taille + 1) % 4
	mfhi $t0
	bnez $t0, doneIf		# (taille + 1) % 4 = 0 -> fin
	la   $a0, saut			
	li   $v0, 4		
	syscall				# imprime "\n"
		
doneIf:
	addi $s1, $s1, 1		# i++ (mot suivant)
	j    forAff

doneAff:	
	lw   $ra, 0($sp)		# récupère adresse de retour
	addi $sp, $sp, 4		# désalloue l'espace
	jr   $ra