#=================================================================#
#06/04/20			Devoir #3 - IFT 1227							#
#																	#
# Elise ZHENG (20148416) - elise.zheng@umontreal.ca				#
# Yuyin DING (20125263)	- yuyin.ding@umontreal.ca					#
#																	#
# Ce programme permet à l'utilisateur d'entrer un texte, puis		#
# retourne chaque mot du texte non trié (dans l'ordre dans lequel #
# il a été entré) puis trié par ordre alphabétique.				#
#=================================================================#

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
msg_erreur: .asciiz   "Votre texte dépasse les 300 caractères!"

#==========================================
# segment de la mémoire contenant le code
.text
main:
	jal saisir
	
	move $t0, $v0			# taille
	addi $t0, $t0, -2
	sb   $0, buffer($t0)	# coupe le texte pour ne pas compter les 2 \n
	
	bge  $t0, 300, erreur	# erreur si texte trop grand (les sauts interlignes sont comptés)
	
	la $a0, msg1			# imprime msg
	li $v0, 4
	syscall
	
	la $a0, buffer			# imprime texte entré
	li $v0, 4
	syscall
	
	la $a0, buffer			# $a0 = texte
	move $a1, $t0			# $a1 = taille
	jal decMots
	
	la $a0, msg2			# imprime msg
	li $v0, 4
	syscall
	
	la $a0, tabMots			# $a0 = tabMots
	move $a1, $v1			# $a1 = taille
	jal afficher			# affiche mots non triés
	
	la $a0, tabMots			# $a0 = tabMots
	move $a1, $v1			# $a1 = taille
	jal trier				# trie mots
	
	la $a0, msg3			# imprime msg
	li $v0, 4
	syscall
	
	la $a0, tabMots			# $a0 = tabMots
	move $a1, $v1			# $a1 = taille
	jal afficher			# affiche mots triés

exit:
	li $v0, 10				# termine le programme
	syscall

erreur:
	la 	$a0, msg_erreur		# imprime msg d'erreur
	li 	$v0, 4
	syscall
	j   exit


# ------------------------------------
# fonction saisir: permet de saisir du texte et s'arrête lorsqu'une ligne vide est entrée
# retourne: $v0 taille du txt en nb octets (nb de caracteres)
# $v0, $a0, $a1, $s0, $t0, $t1
saisir:
	addi $sp, $sp, -4 		# alloue de l'espace
	sw   $ra, 0($sp)		# sauve adresse de retour
	
	la 	 $a0, buffer		# adresse
	li   $a1, 301			# nombre de caractères à lire + 1
	li 	 $v0, 8				# demande input
	syscall
	
	jal getSize				# $s0 = taille du texte
	
whileSaisir:
	#input
	add	 $a0, $a0, $s0		# adresse pour la nouvelle ligne
	li 	 $v0, 8
	syscall

	jal  getSize			# taille de la nouvelle ligne
	
	#while (input.length() != 0)
	li $t0, 1
	beq $s0, $t0, doneSaisir	# si la taille du texte entré est de 0, fin
	
	j    whileSaisir

doneSaisir:
	la 	 $a0, buffer
	jal  getSize
	move $v0, $s0			# retourne la taille
	
	lw   $ra, 0($sp)		# récupère adresse de retour
	addi $sp, $sp, 4		# désalloue l'espace
	jr   $ra

# ------------------------------------
# fonction getSize: retourne la taille du texte à partir d'une adresse entrée
# param: $a0 adresse de début du texte
# retourne: $v0 taille
getSize:
	li   $s0, 0				# int i = 0
	la   $t0, ($a0)			# charge adresse dans une variable tmp

whileSize:
	lb 	 $t1, 0($t0)		# charge caractère (1car = 1byte)
	beqz $t1, doneSize		# si plus de caractere, fin du texte
	addi $s0, $s0, 1		# i++
	addi $t0, $t0, 1		# adresse du caractère suivant
	j    whileSize

doneSize:
	addi $s0, $s0, 0
	jr   $ra
	

# ------------------------------------
# fonction lettre
# $t0 char
# retourne true si maj/min, false sinon
# $t9, $a0, $v0
lettre:
	move $t8, $t0
	sub  $t9, $t8, 65 		# 0 <= car <= 65 ? false
	bltz $t9, falseLettre
	sub  $t9, $t8, 90 		# 65 <= car <= 90 ? true
	bltz $t9, trueLettre
	
	sub  $t9, $t8, 97		# 65 <= car <= 97 ? false
	bltz $t9, falseLettre
	sub  $t9, $t8, 122 		# 97 <= car <= 122 ? true
	bltz $t9, trueLettre
 		
falseLettre:
	li 	 $v0, 0
	jr   $ra

trueLettre:
	li 	 $v0, 1
	jr   $ra


# ------------------------------------
# fonction strCmp : compare str1 et str2, retourne true si str1 <= str2, false sinon
# param: $t2 str1, $t3 str2
# retourne: $v0 boolean
strCmp:
	addi $sp, $sp, -4 		# alloue de l'espace
	sw   $ra, 0($sp)		# sauve l'adresse de retour
	li	 $s7, 0				# i = 0
	move $t8, $t2
	move $t9, $t3

whileCmp:
	lb  $a2, ($t8)			# load car
	lb  $a3, ($t9)			# load car

	blt $a2, $a3, trueCmp	# str1 < str2 ? true
	bgt $a2, $a3, falseCmp # str1 > str2 ? false

	addi $t8, $t8, 1		# sinon on compare les prochains car
	addi $t9, $t9, 1
	
	beqz $a2, trueCmp		# fin du str1 ? true
	beqz $a3, falseCmp		# fin du str2 ? false
	
	j	 whileCmp

trueCmp:
	li   $v0, 1
	j    doneCmp

falseCmp:
	li	 $v0, 0

doneCmp:
	lw   $ra, 0($sp)		# restaure l'adresse de retour
	addi $sp, $sp, 4		# désalloue l'espace
	jr	 $ra

# ------------------------------------
# fonction trier: trie alphabétiquement tabMots avec un bubble sort
# param: $a0 tabMots, $a1 taille
trier:
	addi $sp, $sp, -4 			# alloue de l'espace
	sw   $ra, 0($sp)			# sauve adresse de retour
	li   $t0, 0					# i = 0
	addi $s0, $a1, -1			# taille - 4
	j	 debut
for1:
	addi $t0, $t0, 1			# i++
debut:
	bge  $t0, $s0, doneTrier	# while i < taille - 4
	li   $t1, 0					# j = 0
	sub  $s1, $s0, $t0 			# taille - 1 - 4
		
for2:
	bge	 $t1, $s1 , for1		# while j < taille - 1 - 4
	sll  $t4, $t1, 2			# j*4
	add  $t2, $t4, $a0			# t2 = tabMots[j]
	addi $t3, $t2, 4			# t3 = tabMots[j+1]
	lw	 $t2, ($t2)
	lw   $t3, ($t3)
	jal  strCmp
	addi $t1, $t1, 1			# j++
	bnez $v0, for2				# si dans le bon ordre, on saute

	# swap
	add  $t2, $t4, $a0			# t2 = tabMots[j]
	addi $t3, $t2, 4			# t3 = tabMots[j+1]
	lw   $t4, ($t2)				# tmp = tabMots[j]
	lw   $t5, ($t3)				# tmp = tabMots[j+1]
	sw   $t4, ($t3)				# tabMots[j] = tabMots[j+1]
	sw   $t5, ($t2)				# tabMots[j+1] = tmp 

	j for2

doneTrier:
	lw   $ra, 0($sp)			# récupère adresse de retour
	addi $sp, $sp, 4			# désalloue l'espace
	jr   $ra
	

# ------------------------------------
# fonction decMots: découpe le texte en mots
# param: $a0 texte, $a1 taille
# retourne: $v0 tabMots, $v1 taille
decMots:
	addi $sp, $sp, -4 		# add space
	sw   $ra, 0($sp)
	li   $s0, 0				# nbElem tabMots
	li   $t2, 0				# i = 0

forDecMots:
	bge  $t2, $a1, doneDecMots		# while i < taille
	lb   $t0, buffer($t2)			# $t0 = buffer.charAt(i)
	
	whileNonLetter:
		jal  lettre
		bnez $v0, suite1
		addi $t2, $t2, 1			# i++
		lb   $t0, buffer($t2)
		bge  $t2, $a1, doneDecMots
		j	 whileNonLetter

suite1:	
	la  $t9, buffer($t2)
	sll $t8, $s0, 2					# nbElem * 4
	sw  $t9, tabMots($t8)			# tab[tab.length]

	whileLetter:
		jal  lettre
		addi $t2, $t2, 1			# i++
		lb   $t0, buffer($t2)
		bnez $v0, whileLetter
	
	addi $s0, $s0, 1				# nbElem++
	j    forDecMots

doneDecMots:
	move $v1, $s0					# retourne taille
	lw   $ra, 0($sp)
	addi $sp, $sp, 4
	jr	 $ra
	

# ------------------------------------
# fonction tailleMax: retourne taille du plus long mot dans tabMots
# param: $a0 tabMots, $a1 taille
# retourne: $v0 max
# $t3 = $a1 taille
# $s1 i
# $t5 tmp
# $s0 max
tailleMax:
	addi $sp, $sp, -4 			# alloue de l'espace
	sw   $ra, 0($sp)			# sauve adresse de retour

	li   $s0, 0					# max = 0
	li   $s1, 0					# i = 0
	move $t3, $a1				# taille
	
	li 	 $t1, 4				# 4
	# cas où <= 4 mots
	sge  $t0, $t1, $t3
	addi $t3, $t3, -1		# prend pas en compte dernier mot
	
forTM:
	bge  $s1, $t3, doneTailleMax	# i >= taille ?
	
	# on prend pas en compte du mot qui est affiché en dernier
	addi $t0, $s1, 1		# i + 1
	div  $t0, $t1			# (i + 1) % 4
	mfhi $t0
	beqz $t0, skip			# (i + 1) % 4 = 0 ?


	sll  $t7, $s1, 2			# i * 4
	lw 	 $t2, tabMots($t7)		# adresse du mot i
	li	 $t5, 0					# tmp = 0

	whileTM:
		add  $t0, $t5, $t2
		lb   $t0, ($t0)			# # tabMots[i].charAt(j)
		jal  lettre
		beqz $v0, ifTM			# lettre?
		addi $t5, $t5, 1		# tmp++
		j whileTM

	ifTM:
		slt  $t7, $s0, $t5		# max < tmp ?
		beqz $t7, skip			# sinon, skip
		move $s0, $t5			# max = tmp
	skip:
		addi $s1, $s1, 1
		j forTM	        

doneTailleMax:
	move $v0, $s0				# retourne max
	lw   $ra, 0($sp)			# récupère adresse de retour
	addi $sp, $sp, 4			# désalloue l'espace
	jr   $ra


# ------------------------------------
# fonction afficher: affiche chaque mots de tabMots 4 par 4 et alignés
# param: $a0 tabMots, $a1 taille
afficher:
	addi $sp, $sp, -4 			# alloue de l'espace
	sw   $ra, 0($sp)			# sauve adresse de retour
	
	jal	 tailleMax
	move $s0, $v0				# tailleMax
	li   $s1, 0					# i = 0
	move $s4, $a0

forAff:
	bge  $s1, $a1, doneAff
	sll  $t0, $s1, 2
	add  $s3, $s4, $t0
	lw 	 $s3, ($s3)		# adresse du mot i
	
	# print chaque mot
	li   $s2, 0					# j = 0
	while1:
		add	$t0, $s2, $s3
		lb	$t0, ($t0)			# tabMots[i].charAt(j)
		jal lettre
		beqz $v0, while2		# pas une lettre
		
		move $t6, $a0			# sauve a0 //// mettre a0 autre part des le debut?
		move $a0, $t0			# met t0 a la place de a0
		li 	 $v0, 11			# imprime car
		syscall
		move $a0, $t6			# remet a0
		
		addi $s2, $s2, 1		# j++
		j while1
	
	# ajoute du padding
	while2:
		bgt	 $s2, $s0, if4		# j > max ? sort de la boucle
		li 	 $a0, ' '
		li 	 $v0, 11			# imprime car
		syscall
		addi $s2, $s2, 1		# j++
		j while2
		
	# saute une ligne tous les 4 mots
	if4:
		addi $t0, $s1, 1		# taille + 1
		beq	 $t0, $a1, doneI 	# dernière ligne?
		li 	 $t1, 4				# 4
		div  $t0, $t1			# (taille + 1) % 4
		mfhi $t0
		bnez $t0, doneI			# (taille + 1) % 4 = 0 ?

		la   $a0, saut
		li   $v0, 4
		syscall
		
doneI:
	addi $s1, $s1, 1			# i++
	j    forAff

doneAff:	
	lw   $ra, 0($sp)			# récupère adresse de retour
	addi $sp, $sp, 4			# désalloue l'espace
	jr   $ra
