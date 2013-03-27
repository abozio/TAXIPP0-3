/**********************************************************************************************/
* TAXIPP 0.3 6transferts0_3.do                                                                 *
*                                                                                              *
* Simulation des transferts: prestations familiales, allocations logement, minimas sociaux     *
*                                                                                              *
*                                                                                              *
/**********************************************************************************************/


/* Variables nécessaires : */


  ********************************************************************
	/* 0. Variables sur la structure de la famille et sur les revenus */
	********************************************************************

/* 0.1. : Calcul des variables de nombre d'enfants */
*****************************************************
gen nenf_prest=0
replace nenf_prest=nenf-nenfnaiss if ${annee}==1997
replace nenf_prest=nenf-nenfnaiss+nenfmaj1819 if ${annee}>=1998 
gen npac=nenf_prest+nenf_concu

/* 0.2. Identification des couples biactifs et des parents isolés */
********************************************************************
gen ya_min_biact=0
replace ya_min_biact=${facteur_yamin_biact}*${bmaf_annee_ref} if ${annee}<=2011
replace ya_min_biact=${facteur_yamin_biact}*12*${pss_m_anneeref} if ${annee}==2012

gen biact_or_isole = 0
replace biact_or_isole = 1 if ((couple==1 & ya_irpp>ya_min_biact & ya_irpp~=. & ya_irpp_conj+ya_irpp_concu>ya_min_biact & ya_irpp_conj+ya_irpp_concu~=.) | couple==0)

* Besoin de recalculer ya_irpp_concu

/* 0.3. Variable de ressources pour les prestations */
******************************************************

gen ress_prest = rfr_irpp_foy + rfr_irpp_concu



	**********************************************
	/* 1. Simulation des prestations familiales */
	**********************************************

/* 1.1. Simulation des allocations familiales (AF) */
*****************************************************

	/* Variable dichotomique d'éligibilité au regard des ressources (allocation différentielle non comprise : 
	   éligibilité à l'AF à taux plein) : car en 1998 seulement, les AF étaient sous condition de ressources */
	gen plafond_af=${plaf_af_0enf}+${maj_plaf_af_bi}*cond(biact_or_isole==1,1,0)+${maj_plaf_af_enf}*nenf_prest
	gen elig_af_plein=0
	replace elig_af_plein=1 if ( ${annee}~=1998 | ress_prest<plafond_af)

	/* Calcul du montant d'AF potentiel*/
	gen af_base=12*${bmaf}*(${af_enf2}*cond(npac>=2,1,0)+${af_enf3}*cond(npac>=3,npac-2,0))
	gen af_maj=12*${bmaf}*(${maj_enf1113}*nenf1113+${maj_enf1415}*nenf1415+${maj_enf1619}*(nenf1617+nenfmaj1819))*cond(nenf_prest>=3,1,0)
	replace af_maj=af_maj+12*${bmaf}*(${maj_enf1113}*cond(nenf1113+nenf1415+nenf1617+nenfmaj1819==2,cond(nenf1415+nenf1617+nenfmaj1819<2,1,0),0)+${maj_enf1415}*cond(nenf1415+nenf1617+nenfmaj1819==2,cond(nenf1617+nenfmaj1819<2,1,0),0)+${maj_enf1619}*cond(nenf1617+nenfmaj1819==2,1,0)) if nenf_prest==2
	replace af_maj=af_maj+12*${bmaf}*${for_enf20}*nenfmaj20 if nenf+nenfmaj1819+nenfmaj20>=3

	/* Allocation au niveau du ménage */
	gen af_diff=0
	replace af_diff=plafond_af+af_base+af_maj-ress_prest if ress_prest-plafond_af>=0 & ress_prest-plafond_af<=af_base+af_maj & ${annee}==1998 
	replace af_base=af_base*elig_af_plein
	replace af_maj=af_maj*elig_af_plein

	/* Allocation individuelle */
	replace af_maj=af_maj/2 if couple==1 
	replace af_maj=0 if pac==1
	replace af_base=af_base/2 if couple==1 
	replace af_base=0 if pac==1
	replace af_diff=af_diff/2 if couple==1 
	replace af_diff=0 if pac==1
	gen af=af_base+af_maj+af_diff
	 
/* 1.2. Simulation du complément familial (CF) */
*************************************************

	/* Nombre d'enfants donnant droit au CF */
	gen nenf_cf=0
	replace nenf_cf=nenf-nenf02+nenfmaj1819+nenfmaj20 if ${annee}>=2000
	replace nenf_cf=nenf-nenf02+nenfmaj1819 if ${annee}<2000

	/* Variable dichotomique d'éligibilité au regard des ressources (allocation différentielle non comprise : éligibilité au CF plein) */
	gen maj_plaf_enf_cf_apje_adopt=${maj_plaf_cf_apje_adopt_enf1et2}*min(nenf_cf+nenf02,2)+${maj_plaf_cf_apje_adopt_enf3pl}*max(nenf_cf+nenf02-2,0)
	gen plafond_cf_apje_adopt=(1+maj_plaf_enf_cf_apje_adopt)*${plaf_cf_apje_adopt_0enf}+${maj_plaf_cf_apje_adopt_bi}*cond(biact_or_isole==1,1,0)
	gen elig_cf_plein=0
	replace elig_cf_plein=1 if ress_prest<plafond_cf_apje_adopt

	/* Calcul du montant de CF potentiel */
	gen cfam_plein=0
	replace cfam_plein=12*${bmaf}*${tx_cf if nenf_cf} >= ${nenf_cf_min}

	/* Allocation au niveau du ménage */
	gen cfam_diff = 0
	replace cfam_diff = plafond_cf_apje_adopt+cfam_plein-ress_prest if ress_prest-plafond_cf_apje_adopt>=0 & ress_prest-plafond_cf_apje_adopt <= cfam_plein
	replace cfam_plein = cfam_plein*elig_cf_plein

	/* Allocation individuelle */
	replace cfam_plein=cfam_plein/2 if couple==1
	replace cfam_plein=0 if pac==1
	replace cfam_diff=cfam_diff/2 if couple==1
	replace cfam_diff=0 if pac==1
	gen cfam=cfam_plein+cfam_diff


/* 1.3. Simulation de l'APJE et de la PAJE */
*********************************************

/***** 1.3.1. Simulation de l'APJE (pour les enfants nés avant le 01/01/2004) */

/* Variable dichotomique d'éligibilité au regard des ressources (allocation différentielle non comprise : éligibilité à l'APJE pleine) */
gen elig_apje_plein=0
replace elig_apje_plein=1 if ress_prest<plafond_cf_apje_adopt

/* Calcul du montant d'APJE potentiel */
   /* APJE courte */  
gen apje_c_plein=((7*12+11+10+9+8+7)/12)*${bmaf}*${tx_apje}*nenfnaiss
           /* Ouverture des droits "à compter du premier jour du mois civil suivant le troisième mois de grossesse" (art. R531-1 du CSS). Ici, on ne considère que le mois de naissance 
		      (on suppose que tous les enf naissent en début de mois). Par conséquent, les enfants nés entre janvier et juillet donnent droit à l'APJE pour les 12 mois de l'année. 
			  Puis, le nombre de mois pendant lesquels on touche l'APJE décroit : si l'enf est né début août, il donne droit à l'APJE pendant 11 mois et ainsi de suite. Bref, la moyenne du nombre de mois pendant lesquels 
			  le ménage touche l'APJE si nenfnaiss>0 est de : ((7*12+11+10+9+8+7)/12) */
   /* APJE longue */
gen apje_l_plein=12*${bmaf}*${tx_apje}*cond(nenf02>0,1,0) 
       
   /* APJE totale */
gen apje_plein=apje_c_plein+apje_l_plein

/* Allocation au niveau du ménage */
gen apje_diff=0
replace apje_diff=plafond_cf_apje_adopt+apje_plein-ress_prest if ress_prest-plafond_cf_apje_adopt>=0 & ress_prest-plafond_cf_apje_adopt<=apje_plein
replace apje_c_plein=apje_c_plein*elig_apje_plein
replace apje_l_plein=apje_l_plein*elig_apje_plein
replace apje_plein=apje_plein*elig_apje_plein

/* Allocation individuelle */
replace apje_diff=apje_diff/(1+couple)
replace apje_diff=0 if pac==1
replace apje_c_plein=apje_c_plein/(1+couple)
replace apje_c_plein=0 if pac==1
replace apje_l_plein=apje_l_plein/(1+couple)	
replace apje_l_plein=0 if pac==1  
replace apje_plein=apje_plein/(1+couple)
replace apje_plein=0 if pac==1
gen apje=apje_plein+apje_diff

/***** 1.3.2. Simulation de la PAJE (pour les enfants nés après le 01/01/2004) (prestations simulées: paje_naiss, paje_base, paje_clca) */

gen maj_plaf_enf_paje_base=${maj_plaf_paje_enf1et2}*min(nenf_prest,2)+${maj_plaf_paje_enf3pl}*max(nenf_prest-2,0)
gen maj_plaf_enf_paje_naiss=${maj_plaf_paje_enf1et2}*min(nenf_prest+nenfnaiss,2)+${maj_plaf_paje_enf3pl}*max(nenf_prest+nenfnaiss-2,0)
gen plafond_paje_base=(1+maj_plaf_enf_paje_base)*${plaf_paje_0enf}+${maj_plaf_paje_bi}*cond(biact_or_isole==1,1,0)
gen plafond_paje_naiss=(1+maj_plaf_enf_paje_naiss)*${plaf_paje_0enf}+${maj_plaf_paje_bi}*cond(biact_or_isole==1,1,0)

gen paje_naiss=0
replace paje_naiss=${bmaf}*${tx_paje_naiss}*nenfnaiss if ress_prest<plafond_paje_naiss
replace paje_naiss=paje_naiss/2 if couple==1
replace paje_naiss=0 if pac==1

gen paje_base=0
replace paje_base=12*${bmaf}*${tx_paje_base} if nenf02>0 & ress_prest < plafond_paje_base
replace paje_base=paje_base/2 if couple==1
replace paje_base=0 if pac==1

gen paje_clca=0
replace paje_clca=12*${bmaf}*(cond(paje_base==0,${tx_clca_nonbase},${tx_clca_base})) if nenf02>0 & ya_irpp==0
replace paje_clca=paje_clca/2 if couple==1 & ya_irpp_conj==0
replace paje_clca=0 if pac==1

/***** 1.3.3. On regarde maintenant auquel des deux dispositif le ménage a accés entre l'APJE et la PAJE */

gen applic_apje = 0
replace applic_apje  = 1 if ${annee}<=2004
gen applic_paje      = 1-applic_apje
replace apje_diff    = apje_diff * applic_apje
replace apje_c_plein = apje_c_plein * applic_apje
replace apje_l_plein = apje_l_plein*applic_apje
replace apje_plein   = apje_plein*applic_apje
replace apje         = apje*applic_apje
replace paje_naiss   = paje_naiss*applic_paje
replace paje_base    = paje_base*applic_paje
replace paje_clca    = paje_clca*applic_paje


/* 1.4. Simulation de l'allocation de soutien familial (ASF) */
***************************************************************

gen asf = 0
replace asf = 12*${bmaf}*${asf_1parent}*nenf_prest if couple==0 & pens_alim_rec==0
replace asf = 0 if pac==1

/* 1.5. Simulation de l'allocation de rentrée scolaire (ARS) */
***************************************************************

/* Le calcul de l'ARS se trouve après le calcul de l'ALF car jusqu'en 1998 inclut, son montant dépendait des prestations familiales et des aides aux logement */


/* 1.6. Règles de cumul de différentes prestations (hors API) */
****************************************************************

/* L'allocation de base de la PAJE n'est pas cumulable avec le CF. Les ménages choisissent la prestation la plus élevée */
replace cfam_plein = 0 if cfam < paje_base
replace cfam_diff  = 0 if cfam < paje_base
replace cfam       = 0 if cfam < paje_base
replace paje_base  = 0 if cfam >= paje_base
   

/* On génère la variable "paje" (nous n'avions pas pu avant en raison des calculs sur le non-cumul) */
gen paje = paje_naiss + paje_base + paje_clca


/* 1.7. Variables au niveau foyer */
************************************

gen af_foys         = af*(1+couple)
gen cfam_foys       = cfam*(1+couple)
gen apje_foys       = apje*(1+couple)
gen paje_naiss_foys = paje_naiss*(1+couple)
gen paje_base_foys  = paje_base*(1+couple)
gen paje_clca_foys  = paje_clca*(1+cond(couple==1 & ya_irpp_conj==0,1,0))
gen paje_foys       = paje_naiss_foys+paje_base_foys+paje_clca_foys
gen asf_foys        = asf*(1+couple)

/* 1.8. Total des prestations familiales (avant calcul de l'ARS) */
*******************************************************************

gen pf      = af+cfam+apje+paje+asf
gen pf_foys = (af+cfam+apje+paje_naiss+paje_base+asf)*(1+couple)+paje_clca*(1+cond(couple==1 & ya_irpp_conj==0,1,0))



************************************************************************************************************
/* 2. Simulation des aides au logement : nous simulons seulement l'allocation de logement familiale (ALF) */
************************************************************************************************************

/* 2.1. Détermination des variables communes aux différents volets de l'ALF */
******************************************************************************

/* Variable d'éligibilité */
gen elig_alf=0
replace elig_alf=1 if (nenf_prest>0 & nenf_prest~=.) | (nenf_prest==0 & nenfnaiss>0 & sexe==2 & couple==0 & $annee>=2004)

/* Variables de nombre d'enfants */
gen nenf_alf = nenf_prest+nenf_concu
replace nenf_alf = nenf_prest+nenf_concu+nenfmaj20 if ${annee}>=2000

/* Variable de ressources */
gen ress_alf = ress_prest
replace ress_alf = ${interv_ress}*(int(ress_prest/${interv_ress})+1) if ${annee}>=1998

/* Coefficients servant au calcul des différents volets de l'ALF */
gen coeff_n = ${n_0enf}*cond(nenf_alf==0,1,0)+${n_1enf}*cond(nenf_alf==1,1,0)+${n_2enf}*cond(nenf_alf==2,1,0)+${n_3enf}*cond(nenf_alf==3,1,0)+${n_4enf}*cond(nenf_alf>=4,1,0)+${n_enfsupp}*max(nenf_alf-4,0)
gen coeff_k = max(${cons_k}-(ress_alf/(${mult_k}*coeff_n)),0)

/* Majoration du plafond au titre des charges */
gen plaf_char = 12*(${plaf_char}+${plaf_char_enf}*nenf_alf)
replace plaf_char = 12*(${plaf_char_isol_coloc}+${plaf_char_enf}*nenf_alf) if cohab==1 & couple==0


/* 2.2. Détermination de l'ALF aux accédants à la propriété */
**************************************************************

gen remb = loyer_fictif_men/(1+cohab)

gen plaf_remb = 0
forvalues i=1/3 {
/***zone i (i allant de 1 à 3)*/
replace plaf_remb = 12*${plaf_remb_isol_z`i'} if couple==0 & nenf_alf==0 & zone==`i' 
replace plaf_remb = 12*${plaf_remb_coup_z`i'} if couple==1 & nenf_alf==0 & zone==`i' 
replace plaf_remb = 12*${plaf_remb_enf1_z`i'} if nenf_alf==1 & zone==`i' 
replace plaf_remb = 12*${plaf_remb_enf2_z`i'} if nenf_alf==2 & zone==`i' 
replace plaf_remb = 12*${plaf_remb_enf3_z`i'} if nenf_alf==3 & zone==`i' 
replace plaf_remb = 12*${plaf_remb_enf4_z`i'} if nenf_alf==4 & zone==`i' 
replace plaf_remb = 12*${plaf_remb_enf5_z`i'} if nenf_alf==5 & zone==`i'
replace plaf_remb = 12*${plaf_remb_enf5_z`i'} + 12*${plaf_remb_enfsupp_z`i'}*(nenf_alf-5) if nenf_alf>=6 & zone==`i'
}
	   
	   
gen loy_min = ${lo_tx1}*ress_alf if ress_alf<=coeff_n*${seuil_tr1_lo}
replace loy_min = ${lo_tx1}*coeff_n*${seuil_tr1_lo} + ${lo_tx2}*(ress_alf-coeff_n*${seuil_tr1_lo}) if ress_alf>coeff_n*${seuil_tr1_lo} & ress_alf<=coeff_n*${seuil_tr2_lo}
replace loy_min = ${lo_tx1}*coeff_n*$seuil_tr1_lo + $lo_tx2*coeff_n*($seuil_tr2_lo-$seuil_tr1_lo) + $lo_tx3*(ress_alf-coeff_n*$seuil_tr2_lo) if ress_alf>coeff_n*$seuil_tr2_lo & ress_alf<=coeff_n*$seuil_tr3_lo
replace loy_min = ${lo_tx1}*coeff_n*$seuil_tr1_lo + $lo_tx2*coeff_n*($seuil_tr2_lo-$seuil_tr1_lo) + $lo_tx3*coeff_n*($seuil_tr3_lo-$seuil_tr2_lo) + $lo_tx4*(ress_alf-coeff_n*$seuil_tr3_lo) if ress_alf>coeff_n*$seuil_tr3_lo & ress_alf<=coeff_n*$seuil_tr4_lo
replace loy_min = ${lo_tx1}*coeff_n*$seuil_tr1_lo + $lo_tx2*coeff_n*($seuil_tr2_lo-$seuil_tr1_lo) + $lo_tx3*coeff_n*($seuil_tr3_lo-$seuil_tr2_lo) + $lo_tx4*coeff_n*($seuil_tr4_lo-$seuil_tr3_lo) + $lo_tx5*(ress_alf-coeff_n*$seuil_tr4_lo) if ress_alf>coeff_n*$seuil_tr4_lo

replace loy_min = loy_min+$maj_lo

gen alf_proprio_empr = 0
replace alf_proprio_empr = max(coeff_k*(min(remb,plaf_remb)+plaf_char-loy_min),0) if proprio_empr==1
replace alf_proprio_empr = alf_proprio_empr * elig_alf


/* 2.3. Détermination de l'ALF aux locataires */
************************************************

gen loyer_alf=loyer_verse_men/(1+cohab)

if $annee<2001 {

gen plaf_loyer=0
forvalues i=1/3 {
/***zone i (i allant de 1 à 3)*/
replace plaf_loyer = 12*${plaf_loy_coup_z`i'} if couple==1 & nenf_alf==0 & zone==`i' 
replace plaf_loyer = 12*${plaf_loy_enf1_z`i'} if nenf_alf==1 & zone==`i'
replace plaf_loyer = 12*${plaf_loy_enf2_z`i'} if nenf_alf==2 & zone==`i'
replace plaf_loyer = 12*${plaf_loy_enf3_z`i'} if nenf_alf==3 & zone==`i'
replace plaf_loyer = 12*${plaf_loy_enf4_z`i'} if nenf_alf==4 & zone==`i'
replace plaf_loyer = 12*${plaf_loy_enf5_z`i'} if nenf_alf==5 & zone==`i'
replace plaf_loyer = 12*${plaf_loy_enf5_z`i'}+12*${plaf_loy_enfsupp_z`i'}*(nenf_alf-5) if nenf_alf>=6 & zone==`i'
}

replace plaf_loyer = ${tx_plaf_loy_coloc}*plaf_loyer if cohab==1	   
	   
replace loy_min = $lo_tx1}*ress_alf if ress_alf<=coeff_n*${seuil_tr1_lo}
replace loy_min = ${lo_tx1}*coeff_n*${seuil_tr1_lo} + ${lo_tx2}*(ress_alf-coeff_n*${seuil_tr1_lo}) if ress_alf>coeff_n*${seuil_tr1_lo} & ress_alf<=coeff_n*${seuil_tr2_lo}
replace loy_min = ${lo_tx1}*coeff_n*${seuil_tr1_lo} + ${lo_tx2}*coeff_n*(${seuil_tr2_lo}-${seuil_tr1_lo}) + ${lo_tx3}*(ress_alf-coeff_n*${seuil_tr2_lo}) if ress_alf>coeff_n*${seuil_tr2_lo} & ress_alf<=coeff_n*${seuil_tr3_lo}
replace loy_min = ${lo_tx1}*coeff_n*${seuil_tr1_lo} + ${lo_tx2}*coeff_n*(${seuil_tr2_lo}-${seuil_tr1_lo}) + ${lo_tx3}*coeff_n*(${seuil_tr3_lo}-${seuil_tr2_lo}) + ${lo_tx4}*(ress_alf-coeff_n*${seuil_tr3_lo}) if ress_alf>coeff_n*${seuil_tr3_lo} & ress_alf<=coeff_n*${seuil_tr4_lo}
replace loy_min = ${lo_tx1}*coeff_n*${seuil_tr1_lo} + ${lo_tx2}*coeff_n*(${seuil_tr2_lo}-${seuil_tr1_lo}) + ${lo_tx3}*coeff_n*(${seuil_tr3_lo}-${seuil_tr2_lo}) + ${lo_tx4}*coeff_n*(${seuil_tr4_lo}-${seuil_tr3_lo}) + ${lo_tx5}*(ress_alf-coeff_n*${seuil_tr4_lo}) if ress_alf>coeff_n*${seuil_tr4_lo}

replace loy_min = loy_min+${maj_lo}

gen alf_locat = 0
replace alf_locat = max(coeff_k*(min(loyer_alf,plaf_loyer)+plaf_char-loy_min),0) if locat==1
replace alf_locat = alf_locat*elig_alf
}


if $annee>=2001 {

gen plaf_loyer=0
forvalues i=1/3 {
/***zone i (i allant de 1 à 3)*/
replace plaf_loyer = 12*${plaf_loy_isol_z`i'} if couple==0 & nenf_alf==0 & zone==`i'
replace plaf_loyer = 12*${plaf_loy_coup_z`i'} if couple==1 & nenf_alf==0 & zone==`i'
replace plaf_loyer = 12*${plaf_loy_enf1_z`i'} if nenf_alf==1 & zone==`i'
replace plaf_loyer = 12*${plaf_loy_enf1_z`i'}+12*${plaf_loy_enfsupp_z`i'}*(nenf_alf-1) if nenf_alf>1 & zone==`i'
}

replace plaf_loyer=${tx_plaf_loy_coloc}*plaf_loyer if cohab==1

gen alf_max=0
replace alf_max=min(loyer_alf,plaf_loyer)+plaf_char
gen p0=max(${p0_cons},${p0_tx}*alf_max)

gen rp=0
gen r0=0
gen tx_r1 = ${r1_isol}*cond(couple==0 & nenf_alf==0,1,0)+${r1_coup}*cond(couple==1 & nenf_alf==0,1,0)+${r1_enf1}*cond(nenf_alf==1,1,0)+${r1_enf2}*cond(nenf_alf==2,1,0)+(${r1_enf2}+${r1_enfsupp}*(nenf_alf-2))*cond(nenf_alf>2,1,0)
gen tx_r2 = ${r2_enf2}*cond(nenf_alf==2,1,0)+(${r2_enf2}+${r2_enfsupp}*(nenf_alf-2))*cond(nenf_alf>2,1,0)
gen tx_plaf_r0 = ${tx_plaf_r0_enf0}*cond(nenf_alf==0,1,0)+${tx_plaf_r0_enf1}*cond(nenf_alf==1,1,0)+${tx_plaf_r0_enf2}*cond(nenf_alf==2,1,0)+${tx_plaf_r0_enf3}*cond(nenf_alf==3,1,0)+${tx_plaf_r0_enf4pl}*cond(nenf_alf>=4,1,0)
replace r0 = (1-${tx_abt_sal})*(1-${tx_ded_sal})*12*(tx_r1*${brmirsa_annee_ref}-tx_r2*${bmaf_annee_ref})
replace r0 = tx_plaf_r0*r0
replace rp = max(0,ress_prest-r0)

gen tf = 0
replace tf = ${tf_isol}                                 if couple==0 & nenf_alf==0
replace tf = ${tf_coup}                                 if couple==1 & nenf_alf==0
replace tf = ${tf_enf1}                                 if nenf_alf==1
replace tf = ${tf_enf2}                                 if nenf_alf==2
replace tf = ${tf_enf3}                                 if nenf_alf==3
replace tf = ${tf_enf4}                                 if nenf_alf==4
replace tf = ${tf_enf4}+max(nenf_alf-4,0)*${tf_enfsupp} if nenf_alf>4

gen loyer_ref=0
replace loyer_ref = 12*${plaf_loy_isol_z2}                                        if couple==0 & nenf_alf==0
replace loyer_ref = 12*${plaf_loy_coup_z2}                                        if couple==1 & nenf_alf==0
replace loyer_ref = 12*${plaf_loy_enf1_z2}                                        if nenf_alf==1
replace loyer_ref = 12*${plaf_loy_enf1_z2}+12*${plaf_loy_enfsupp_z2}*(nenf_alf-1) if nenf_alf>1

gen ratio_loyer_ref=min(plaf_loyer,loyer_alf)/loyer_ref

gen tl = 0
replace tl = ${tl_0}*ratio_loyer_ref if ratio_loyer_ref<=${tl_tr1}
replace tl = ${tl_0}*${tl_tr1}+${tl_1}*(ratio_loyer_ref-${tl_tr1})                               if ratio_loyer_ref>${tl_tr1} & ratio_loyer_ref<=$tl_tr2
replace tl = ${tl_0}*${tl_tr1}+${tl_1}*(${tl_tr2}-${tl_tr1})+${tl_2}*(ratio_loyer_ref-${tl_tr2}) if ratio_loyer_ref>$tl_tr2

gen pp=p0+(tf+tl)*rp

gen alf_locat=0
replace alf_locat=max(alf_max-pp,0) if locat==1
replace alf_locat=alf_locat*elig_alf

}

/* 2.4. Suppression de certaines variables */
*********************************************
drop elig_alf

/* 2.5. Détermination de l'ALF effectivement versée au niveau du ménage */
**************************************************************************
replace alf_proprio_empr = 0    if alf_proprio_empr < 12*$min_alf
replace alf_locat = 0           if alf_locat < 12*$min_alf

/* 2.6. Détermination de l'ALF individuelle */
**********************************************
replace alf_proprio_empr = alf_proprio_empr/(1+couple)
replace alf_proprio_empr = 0 if pac==1
replace alf_locat = alf_locat/(1+couple)
replace alf_locat = 0 if pac==1
gen alf = alf_proprio_empr+alf_locat
gen alf_foys = alf*(1+couple)



/* 1.5 déplacée. Détermination de l'ARS */
********************************************

/* Variable dichotomique d'éligibilité au regard des ressources (allocation différentielle non comprise : éligibilité à l'ARS pleine) */
gen plafond_ars = ${plaf_ars_0enf}*(1+${maj_plaf_ars_enf}*nenf_prest)
gen elig_ars_plein = 0
replace elig_ars_plein = 1 if ress_prest<plafond_ars
	 
/* Calcul du montant d'ARS potentiel*/
gen ars_plein = 0
replace ars_plein = ${bmaf}*(${ars610}*nenf610+${ars1114}*nenf1113+${ars1517}*(nenf1415+nenf1617))+${maj_ars}

/* Allocation au niveau du ménage (avant l'application de la condition sur les autres aides) */
gen ars_diff = 0
replace ars_diff = plafond_ars+ars_plein-ress_prest if ress_prest-plafond_ars>=0 & ress_prest-plafond_ars<=ars_plein & $annee>=2002
replace ars_diff = 0 if ars_diff<12*$min_ars
replace ars_plein = ars_plein*elig_ars_plein
replace ars_plein = 0 if ars_plein<12*$min_ars

/* Allocation au niveau du ménage (après application de la condition sur les autres aides) */
replace ars_diff  = 0 if pf_foys==0 & alf_foys==0 & $annee<=1998
replace ars_plein = 0 if pf_foys==0 & alf_foys==0 & $annee<=1998

/* Allocation individuelle */
replace ars_diff  = ars_diff/2 if couple==1
replace ars_diff  = 0          if pac==1
replace ars_plein = ars_plein/2 if couple==1
replace ars_plein = 0           if pac==1
gen ars = ars_diff+ars_plein

gen ars_foys = ars*(1+couple)

/* Actualisation des variables */
replace pf      = pf+ars
replace pf_foys = pf_foys+ars_foys



	***************************************
	/* 3. Simulation des minimas sociaux */
	***************************************

/* 3.0. Calcul des variables de ressources au niveau du foyer social */
***********************************************************************
*cette définition ne va pas, il faut l'adapter
gen y_foys  = y_irpp_foy - csg_yk_foy - crds_yk_foy - csk_foy + pens_alim_rec_foy + pf_foys + alf_foys + y_irpp_concu
gen ya_foys = ya_irpp_foy+ya_irpp_concu

/* 3.1. Simulation de l'allocation de parent isolé (API) */
***************************************************************************
	   	
/* Calcul de l'allocation maximale */
gen api_max=0
replace api_max=12*${bmaf}*(${api_enceinte}+npac*${api_enf}) if couple==0 & nenf02+nenfnaiss>0
gen api_logt=0
replace api_logt=12*(cond(1+couple+npac==1,1,0)*min(cond(alf_foys>0,alf_foys,${api_logt1}*${bmaf}),${api_logt1}*${bmaf})+cond(1+couple+npac==2,1,0)*min(cond(alf_foys>0,alf_foys,$api_logt2*$bmaf),$api_logt2*$bmaf)+cond(1+couple+npac>=3,1,0)*min(cond(alf_foys>0,alf_foys,$api_logt3*$bmaf),$api_logt3*$bmaf)) if api_max>0
replace api_logt=12*(cond(1+couple+npac==1,1,0)*min(cond(alf_foys>0,alf_foys,$rsa_rmi_logt1*$brmi),$rsa_rmi_logt1*$brmi)+cond(1+couple+npac==2,1,0)*min(cond(alf_foys>0,alf_foys,$rsa_rmi_logt2*$brmi*(1+$rsa_rmi_enf1)),$rsa_rmi_logt2*$brmi*(1+$rsa_rmi_enf1))+cond(1+couple+npac>=3,1,0)*min(cond(alf_foys>0,alf_foys,$rsa_rmi_logt3*$brmi*(1+$rsa_rmi_enf1+$rsa_rmi_enf2)),$rsa_rmi_logt3*$brmi*(1+$rsa_rmi_enf1+$rsa_rmi_enf2))) if api_max>0 & $annee>=2007
replace api_logt=0 if locat==1 & alf_foys==0
replace api_max=api_max-api_logt

/* Calcul des ressources à prendre en compte */
gen y_api=0
replace y_api=max(y_foys-ars*(1+couple)-6*${bmaf}*${tx_apje}*nenfnaiss-alf_foys,0) if ${annee}>=1997 & ${annee}<=2003
 /* Il faut retirer l'APJE courte : celle due à compter du mois suivant le 3ème mois de grossesse et jusqu'au 
    mois où l'enfant fait ses trois mois inclus
    => on devrait retirer des sommes pour les enfants nés en novembre et décembre de l'année N-1. Mais, on ne les
	identifie pas => on se limite aux enfants nés à l'année N. 
	Pour ces enfants-là, on doit retirer au max 9 mois d'APJE courte et au minimum 3 mois. On prend le nombre entre
	les deux, c'est à dire 6. 
*/
replace y_api=max(y_foys-(ars+paje_naiss)*(1+couple)-((2/3)*3+(1/3)*2.5)*${bmaf}*${tx_paje_base}*nenfnaiss-alf_foys,0) if ${annee}>=2004
/* Il faut retirer l'allocation de base de la PAJE due jusqu'aux 3 mois de l'enfant. Soit l'enfant est né pendant l'année N-1 et il n'est pas possible d'identifier un tel enfant avec nos données, 
   soit l'enfant est né pendant l'année N et on retire 4 mois d'alloc, sauf si l'enf est né avant septembre. Donc, dans 1 cas sur 3 (ie. 4 cas sur 12), on doit retirer au min 1 mois d'alloc et au max 4 mois d'alloc 
   => en moyenne : 2.5) 
*/
     
	 
/* Calcul de l'allocation individuelle */
gen api=max(api_max-y_api,0)
replace api=0 if pac==1



/* 3.2. Simulation du minimum vieillesse */
*******************************************

	/***** 3.2.1. Calcul des ressources à prendre en compte */
	
	/* QL: pas satisfaisant : Il faut transformer les revenus irpp du concubin et du capital en revenus bruts
	Tant qu'on n'a pas d'identifiant de foyer social, on n'aura pas mieux !! */
	
	gen y_mv_brut = sal_brut + nonsal_brut + pension_brut + chom_brut + pens_alim_rec_foy + rfin_pv_irpp + rfon_irpp + y_irpp_concu 
	gen y_mv      = max(y_mv_brut - loyer_marche_men, 0 )

	/***** 3.2.2. Calcul de l'ancien minimumm vieillesse */
	
	/* Création d'une variable égale à 1 si le conjoint de l'individu est considéré comme "à charge" selon la législation du minimum vieillesse  */  
	gen conj_charge     = 0
	replace conj_charge = 1 if couple==1 & age_conj>=${age_min_mv} & y_irpp_conj+y_irpp_concu + ${maj_avts_conj} < ${plaf_mv_seul}
 
	/* Création d'une variable égale à 1 si l'individu est considéré comme "à charge" pour son conjoint selon la législation du minimum vieillesse */
	gen pers_charge     = 0 
	replace pers_charge = 1 if couple==1 & age>=${age_min_mv} & y_irpp+${maj_avts_conj}<${plaf_mv_seul}

	gen avts_majore_enf = ${avts}*(1+${maj_avts_enf}*cond(nenf + nenfmaj + nenf_concu > =${nenf_min_maj_mv},1,0))
	
	gen mv_max     = 0
	replace mv_max = (avts_majore_enf+${alloc_sup_seul})*cond(age>=${age_min_mv},1,0) if couple==0
	replace mv_max = 0 if couple==1 & age<${age_min_mv} & age_conj<${age_min_mv}
	replace mv_max = (avts_majore_enf+${alloc_sup_men}) if couple==1 & ((age>=${age_min_mv} & age_conj<${age_min_mv}) | (age_conj>=${age_min_mv} & age<${age_min_mv}))
	replace mv_max = avts_majore_enf+${maj_avts_conj}+${alloc_sup_men} if couple==1 & age>=${age_min_mv} & age_conj>=${age_min_mv} & ((conj_charge==1 & pers_charge==0) | (conj_charge==0 & pers_charge==1))
	replace mv_max = 2*avts_majore_enf+${alloc_sup_men} if couple==1 & age>=${age_min_mv} & age_conj>=${age_min_mv} & ((conj_charge==1 & pers_charge==1) | (conj_charge==0 & pers_charge==0))

	gen mv_foys_anc = 0
	replace mv_foys_anc = min(mv_max,max(${plaf_mv_seul}-y_mv,0)) if couple==0
	replace mv_foys_anc = min(mv_max,max(${plaf_mv_men}-y_mv,0)) if couple==1


	/***** 3.2.3. Calcul du nouveau minimumm vieillesse (l'ASPA) */

	gen mv_foys_nouv     = 0
	replace mv_foys_nouv = min($aspa_seul,max($plaf_mv_seul-y_mv,0)) if couple==0 & age>=$age_min_mv
	replace mv_foys_nouv = min($aspa_seul,max($plaf_mv_men-y_mv,0)) if couple==1 & ((age>=$age_min_mv & age_conj<$age_min_mv) | (age_conj>=$age_min_mv & age<$age_min_mv))
	replace mv_foys_nouv = min($aspa_men,max($plaf_mv_men-y_mv,0)) if couple==1 & age>=$age_min_mv & age_conj>=$age_min_mv

	/***** 3.2.4. Choix entre ces deux minimum vieillesse */

	gen nouveau_mv = 0
	gen ancien_mv  = 0

	replace ancien_mv  = 1 if ${annee}<=2006
	replace ancien_mv  = 1 if ${annee}>=2007 & couple==0 & age - ${age_min_mv}>${annee}-2007
	replace ancien_mv  = 1 if ${annee}>=2007 & couple==1 & age >= ${age_min_mv} & age_conj<${age_min_mv} & age-${age_min_mv}>${annee}-2007
	replace ancien_mv  = 1 if ${annee}>=2007 & couple==1 & age < ${age_min_mv} & age_conj>=${age_min_mv} & age_conj-${age_min_mv}>${annee}-2007
	replace ancien_mv  = 1 if ${annee}>=2007 & couple==1 & age >= ${age_min_mv} & age_conj>=${age_min_mv} & min(age,age_conj)-${age_min_mv}>${annee}-2007

	replace nouveau_mv = 1 if ${annee}>=2007 & couple==0 & age-${age_min_mv}<=${annee}-2007
	replace nouveau_mv = 1 if ${annee}>=2007 & couple==1 & age>=${age_min_mv} & age_conj<${age_min_mv} & age-${age_min_mv}<=${annee}-2007
	replace nouveau_mv = 1 if ${annee}>=2007 & couple==1 & age<${age_min_mv} & age_conj>=${age_min_mv} & age_conj-${age_min_mv}<=${annee}-2007
	replace nouveau_mv = 1 if ${annee}>=2007 & couple==1 & age>=${age_min_mv} & age_conj>=${age_min_mv} & min(age,age_conj)-${age_min_mv}<=${annee}-2007

	gen mv_foys     = 0
	replace mv_foys = ancien_mv*mv_foys_anc+nouveau_mv*mv_foys_nouv
	replace mv_foys = 0 if pac==1

	/***** 3.2.5. Calcul du montant individuel */
	gen mv = mv_foys/(1+couple)




/* 3.3. Simulation du RMI/RSA */
*******************************			  		 

	/***** 3.3.1. Calcul du RMI (avant 2010, même si réforme : juillet 2009) : */
			  
		/* Calcul de l'allocation maximale */
		gen rmi_max = 12*$brmi*(1+couple*$rsa_rmi_coup)
		replace rmi_max = rmi_max+12*$brmi*(cond(npac>=1,1,0)*$rsa_rmi_enf1+cond(npac>=2,1,0)*$rsa_rmi_enf2+max(npac-2,0)*$rsa_rmi_enf3) if couple==0 & nenf02+nenfnaiss==0
		replace rmi_max = rmi_max+12*$brmi*(min(npac,2)*$rsa_rmi_enf2+max(npac-2,0)*$rsa_rmi_enf3) if couple==1
		gen rmi_logt = 12*(cond(1+couple+npac==1,1,0)*min(cond(alf_foys>0,alf_foys,$rsa_rmi_logt1*$brmi),$rsa_rmi_logt1*$brmi)+cond(1+couple+npac==2,1,0)*min(cond(alf_foys>0,alf_foys,$rsa_rmi_logt2*$brmi*(1+$rsa_rmi_enf1)),$rsa_rmi_logt2*$brmi*(1+$rsa_rmi_enf1))+cond(1+couple+npac>=3,1,0)*min(cond(alf_foys>0,alf_foys,$rsa_rmi_logt3*$brmi*(1+$rsa_rmi_enf1+$rsa_rmi_enf2)),$rsa_rmi_logt3*$brmi*(1+$rsa_rmi_enf1+$rsa_rmi_enf2)))
		replace rmi_logt = 0 if locat==1 & alf_foys==0
		replace rmi_max = rmi_max-rmi_logt

		/* Calcul des ressources à prendre en compte */
		gen y_rmi_rsa = 0
		replace y_rmi_rsa = max(y_foys-ars*(1+couple)-alf_foys,0) if ${annee}==1997 | ${annee}==1998
		replace y_rmi_rsa = max(y_foys-(ars+af_maj)*(1+couple)-4*${bmaf}*${tx_apje}*nenfnaiss-alf_foys,0) if ${annee}>=1999 & ${annee}<=2003
				   /* On retire l'APJE due au titre de la grossesse et jusqu'au mois de naissance inclus. 
				      Or, ouverture des droits à l'APJE "à compter du premier jour du mois civil suivant 
					  le troisième mois de grossesse" (art. R531-1 du CSS). 
					  Donc, au plus, on doit retirer 7 fois l'APJE mensuelle et au moins 1 fois 
					  => on prend le milieu, à savoir 4 
				   */

		replace y_rmi_rsa = max(y_foys-(ars+af_maj+paje_naiss)*(1+couple)-${bmaf}*${tx_paje_base}*nenfnaiss-alf_foys,0) if ${annee}>=2004

		/* Calcul de l'allocation au niveau du foyer */
		gen rmi_foys = max(rmi_max-y_rmi_rsa,0)
		replace rmi_foys = 0 if age<$age_rsa_rmi & age_conj<$age_rsa_rmi & npac+nenfnaiss==0
		replace rmi_foys = 0 if rmi_foys<12*$min_rsa_rmi
		replace rmi_foys = 0 if pac==1

		/* Allocation individuelle */
		gen rmi = rmi_foys/(1+couple)



	/***** 3.3.2. Calcul du RSA : (après 2010, même si réforme : juillet 2009) */

		/* Calcul de l'allocation maximale */
		gen rsa_max = 12*$brsa*(1+couple*$rsa_rmi_coup)
		replace rsa_max = rsa_max+12*$brsa*(cond(npac>=1,1,0)*$rsa_rmi_enf1+cond(npac>=2,1,0)*$rsa_rmi_enf2+max(npac-2,0)*$rsa_rmi_enf3) if couple==0 & nenf02+nenfnaiss==0
		replace rsa_max = rsa_max+12*$brsa*(min(npac,2)*$rsa_rmi_enf2+max(npac-2,0)*$rsa_rmi_enf3) if couple==1
		replace rsa_max = 12*$brsa*($rsa_isole_enceinte+npac*$rsa_isole_enf) if couple==0 & nenf02+nenfnaiss>0
		
		gen rsa_logt = 12*(cond(1+couple+npac==1,1,0)*min(cond(alf_foys>0,alf_foys,$rsa_rmi_logt1*$brsa),$rsa_rmi_logt1*$brsa)+cond(1+couple+npac==2,1,0)*min(cond(alf_foys>0,alf_foys,$rsa_rmi_logt2*$brsa*(1+$rsa_rmi_enf1)),$rsa_rmi_logt2*$brsa*(1+$rsa_rmi_enf1))+cond(1+couple+npac>=3,1,0)*min(cond(alf_foys>0,alf_foys,$rsa_rmi_logt3*$brsa*(1+$rsa_rmi_enf1+$rsa_rmi_enf2)),$rsa_rmi_logt3*$brsa*(1+$rsa_rmi_enf1+$rsa_rmi_enf2)))
		replace rsa_logt = 0 if locat==1 & alf_foys==0
		replace rsa_max = rsa_max-rsa_logt

		/* Calcul de l'allocation au niveau du foyer */
		gen rsa_foys=max(rsa_max+$tx_rsa*ya_foys-y_rmi_rsa,0)
		replace rsa_foys=0 if age<$age_rsa_rmi & age_conj<$age_rsa_rmi & npac+nenfnaiss==0
		gen rsa_soc_foys=max(rsa_max-y_rmi_rsa,0)
		gen rsa_act_foys=rsa_foys*cond(y_rmi_rsa>rsa_max,1,0) + (rsa_foys-rsa_soc_foys)*cond(y_rmi_rsa<=rsa_max,1,0)
		replace rsa_foys=0 if rsa_foys<12*$min_rsa_rmi
		replace rsa_soc_foys=0 if rsa_foys<12*$min_rsa_rmi
		replace rsa_act_foys=0 if rsa_foys<12*$min_rsa_rmi
		replace rsa_foys=0 if pac==1
		replace rsa_soc_foys=0 if pac==1
		replace rsa_act_foys=0 if pac==1

		/* Allocation individuelle */
		gen rsa=rsa_foys/(1+couple)
		gen rsa_soc=rsa_soc_foys/(1+couple)
		gen rsa_act=rsa_act_foys/(1+couple)



*********************************************
/* 4. Calcul de la CRDS sur les transferts */
*********************************************

/* Au niveau foyer */
gen crds_af_foys      = af_foys*$crds
gen crds_cfam_foys    = cfam_foys*$crds
gen crds_ars_foys     = ars_foys*$crds
gen crds_apje_foys    = apje_foys*$crds
gen crds_paje_foys    = paje_foys*$crds
gen crds_asf_foys     = asf_foys*$crds
gen crds_alf_foys     = alf_foys*$crds
gen crds_rsa_act_foys = rsa_act_foys*$crds
gen crds_transf_foys  = crds_af_foys+crds_cfam_foys+crds_ars_foys+crds_apje_foys+crds_paje_foys+crds_asf_foys+crds_alf_foys+crds_rsa_act_foys

/* Au niveau individuel */
gen crds_af      = af*$crds
gen crds_cfam    = cfam*$crds
gen crds_ars     = ars*$crds
gen crds_apje    = apje*$crds
gen crds_paje    = paje*$crds
gen crds_asf     = asf*$crds
gen crds_alf     = alf*$crds
gen crds_rsa_act = rsa_act*$crds
gen crds_transf  = crds_af+crds_cfam+crds_ars+crds_apje+crds_paje+crds_asf+crds_alf+crds_rsa_act


*************************************
/* 5. Calculs de variables finales */
*************************************

/* Transferts du foyer */
gen transf_foys     = pf_foys + alf_foys + mv_foys + rmi_foys + api + rsa_foys
gen transf_net_foys = transf_foys - crds_transf_foys

/* Transferts au niveau individuel */
gen transf = pf + alf + mv + rmi + api + rsa
gen transf_net = transf - crds_transf


*********************************************
/*6. Calculs de variables avec non-recours */
*********************************************

/* 6.1. Pour le RSA */
**********************

g takeup_rsa = 0
replace takeup_rsa = 1-${nontakeup_rsa_soc_0enf}       if rsa_soc>0 & rsa_act==0 & npac==0
replace takeup_rsa = 1-${nontakeup_rsa_soc_1enf}       if rsa_soc>0 & rsa_act==0 & npac==1 
replace takeup_rsa = 1-${nontakeup_rsa_soc_2plenf}     if rsa_soc>0 & rsa_act==0 & npac>=2 
replace takeup_rsa = 1-${nontakeup_rsa_soc_act_0enf}   if rsa_soc>0 & rsa_act>0 & npac==0
replace takeup_rsa = 1-${nontakeup_rsa_soc_act_1enf}   if rsa_soc>0 & rsa_act>0 & npac==1
replace takeup_rsa = 1-${nontakeup_rsa_soc_act_2plenf} if rsa_soc>0 & rsa_act>0 & npac>=2
replace takeup_rsa = 1-${nontakeup_rsa_act_0enf}       if rsa_soc==0 & rsa_act>0 & npac==0
replace takeup_rsa = 1-${nontakeup_rsa_act_1enf}       if rsa_soc==0 & rsa_act>0 & npac==1
replace takeup_rsa = 1-${nontakeup_rsa_act_2plenf}     if rsa_soc==0 & rsa_act>0 & npac>=2

set seed 1234
bys takeup_rsa: g uni_rsa=uniform() if rsa>0
g rsa_taker=(uni_rsa<=takeup_rsa)
foreach var of varlist rsa rsa_soc rsa_act rsa_foys rsa_soc_foys rsa_act_foys {
	gen `var'_reel=`var'*rsa_taker
	}


/* 6.2. Pour le RMI et l'API */
*******************************

g takeup_rmi_api=0
replace takeup_rmi_api = 1-${nontakeup_rmi_api_coup_0enf}     if couple==1 & npac==0
replace takeup_rmi_api = 1-${nontakeup_rmi_api_coup_enfless3} if couple==1 & nenf02>0
replace takeup_rmi_api = 1-${nontakeup_rmi_api_coup_enfpl3}   if couple==1 & npac>0 & nenf02==0
replace takeup_rmi_api = 1-${nontakeup_rmi_api_isol_0enf}     if couple==0 & npac==0
replace takeup_rmi_api = 1-${nontakeup_rmi_api_isol_enfless3} if couple==0 & nenf02>0
replace takeup_rmi_api = 1-${nontakeup_rmi_api_isol_enfpl3}   if couple==0 & npac>0 & nenf02==0

set seed 1234
bys takeup_rmi_api: g uni_rmi_api=uniform() if rmi>0 | api>0
g rmi_api_taker=(uni_rmi_api<=takeup_rmi_api)
foreach var of varlist api rmi rmi_foys {
	gen `var'_reel=`var'*rmi_api_taker
	}

/* 6.3. Pour les allocations logement */
****************************************

g takeup_alloc_lgt=0
replace takeup_alloc_lgt = 1-${nontakeup_alloc_lgt_loc} if locat==1
replace takeup_alloc_lgt = 1-${nontakeup_alloc_lgt_acc} if proprio_empr==1

set seed 1234
bys takeup_alloc_lgt: g uni_alloc_lgt=uniform() if alf>0
g alloc_lgt_taker=(uni_alloc_lgt<=takeup_alloc_lgt)
foreach var of varlist alf alf_foys {
	gen `var'_reel=`var'*alloc_lgt_taker
	}

/* 6.4. Pour le minimum vieillesse */
*************************************

/* Calcul du nombre d'année depuis lesquelles le ménage est éligible au minimum vieillesse */
gen age_max = max(age,age_conj)
gen nb_annee_mv     = max(age_max-${age_min_mv},0)
replace nb_annee_mv = 0 if mv_foys==0

/* On en déduit le taux de non-recours */
gen takeup_mv = 0
replace takeup_mv = 1-${retard_mv_less2} + ${retard_mv_2_5} + ${retard_mv_5_10} + ${retard_mv_10_pl} if nb_annee_mv<2
replace takeup_mv = 1-${retard_mv_2_5}   + ${retard_mv_5_10}+ ${retard_mv_10_pl} if nb_annee_mv>=2 & nb_annee_mv<5
replace takeup_mv = 1-${retard_mv_5_10}  + ${retard_mv_10_pl} if nb_annee_mv>=5 & nb_annee_mv<10
replace takeup_mv = 1-${retard_mv_10_pl} if nb_annee_mv>=10

/* On calcule le MV réellement versé, après prise en compte du non-recours */
set seed 1234
bys takeup_mv: g uni_mv=uniform() if mv>0
g mv_taker=(uni_mv<=takeup_mv)
foreach var of varlist mv mv_foys {
	gen `var'_reel=`var'*mv_taker
	}


/* 6.5. On calcule les variables finales après non-recours */
*************************************************************

/* Transferts du foyer */
gen transf_foys_reel = pf_foys + alf_foys_reel + mv_foys_reel + rmi_foys_reel + api_reel + rsa_foys_reel

/* Transferts au niveau individuel */
gen transf_reel = pf + alf_reel + mv_reel + rmi_reel + api_reel + rsa_reel

/* CRDS au niveau foyer */
gen crds_alf_foys_reel = alf_foys_reel*$crds
gen crds_rsa_act_foys_reel = rsa_act_foys_reel*$crds
gen crds_transf_foys_reel = crds_af_foys + crds_cfam_foys + crds_ars_foys + crds_apje_foys + crds_paje_foys + crds_asf_foys + crds_alf_foys_reel + crds_rsa_act_foys_reel

/* CRDS au niveau individu */
gen crds_alf_reel = alf_reel*$crds
gen crds_rsa_act_reel = rsa_act_reel*$crds
gen crds_transf_reel = crds_af + crds_cfam + crds_ars + crds_apje + crds_paje + crds_asf + crds_alf_reel + crds_rsa_act_reel



******************************************
/* 7. Simulation de la PPE  */
******************************************
	
	/**** phase 7-1: calcul du revenu d'activité individuel au sens PPE */
	/* QL: L'abattement n'est que sur les revenus non-salariaux ? */
		gen ya_ppe        = sal_irpp + nonsal_irpp / (1-${tx_abt_sal}) 
		gen ya_ppe_pt     = ya_ppe            if nbh >= ${htp} | ya_ppe==0
		replace ya_ppe_pt = ya_ppe*${htp}/nbh if nbh < ${htp}

	/**** phase 7-2: formule de base en fonction du revenu d'activité individuel */
		gen ya_ppe_conj = sal_irpp_conj + nonsal_irpp_conj/(1-${tx_abt_sal})

		gen ppe=0 
		replace ppe=${tx_ppe}*ya_ppe_pt if ya_ppe>=${seuil_ppe_min} & ya_ppe_pt<=${seuil_ppe}
		replace ppe=${tx_ret_ppe}*(${seuil_ppe_max}-ya_ppe_pt) if ya_ppe_pt>${seuil_ppe} & ya_ppe_pt<=${seuil_ppe_max}
		replace ppe=0 if ya_ppe_conj>${seuil_ppe_max}
		replace ppe = ppe*2 if ${annee_sim} == 2000

	* ppe pour le conjoint d'un couple marié ou pacsé (hypothèse : il est forcément à temps complet) :  
		gen ppe_conj=0 
		replace ppe_conj=${tx_ppe}*ya_ppe_conj if ya_ppe_conj>=${seuil_ppe_min} & ya_ppe_conj<=${seuil_ppe} & marie==1
		replace ppe_conj=${tx_ret_ppe}*(${seuil_ppe_max}-ya_ppe_conj) if ya_ppe_conj>${seuil_ppe} & ya_ppe_conj<=${seuil_ppe_max} & marie==1
		replace ppe_conj=0 if ya_ppe_conj>${seuil_ppe_max} & marie==1
		replace ppe_conj = ppe_conj*2 if ${annee_sim} == 2000

		
	/**** phase 7-3: supplément couples mono-emploi */
	
		gen sup_ppe=0
		replace sup_ppe = ${supp_ppe_coup} if ya_ppe >= ${seuil_ppe_min} & ya_ppe_pt <= ${seuil_ppe_coup} & marie==1 & ya_ppe_conj<${seuil_ppe_min} 
		replace ppe=${tx_ret_ppe_coup}*(${seuil_ppe_max_coup}-ya_ppe_pt) if ya_ppe_pt>${seuil_ppe_coup} & ya_ppe_pt<=${seuil_ppe_max_coup} & marie==1 & ya_ppe_conj<${seuil_ppe_min} 

		* ppe pour le conjoint d'un couple marié ou pacsé
		gen sup_ppe_conj = 0
		replace sup_ppe_conj = ${supp_ppe_coup} if ya_ppe_conj>=${seuil_ppe_min} & ya_ppe_conj<=${seuil_ppe_coup} & marie==1 & ya_ppe_pt<${seuil_ppe_min} 
		replace ppe_conj=${tx_ret_ppe_coup}*(${seuil_ppe_max_coup}-ya_ppe_conj) if ya_ppe_conj>${seuil_ppe_coup} & ya_ppe_conj<=${seuil_ppe_max_coup} & marie==1 & ya_ppe_pt<${seuil_ppe_min} 

	/**** phase 7-4: supplément personnes à charge */
		gen ppe_enf=0
		replace ppe_enf=${supp_ppe_enf}*(nenf+nenfmaj) if ya_ppe>=${seuil_ppe_min} & ya_ppe_pt<=${seuil_ppe_max} & pac==0 & (ya_ppe_conj<${seuil_ppe_min} | ya_ppe_conj>${seuil_ppe_max})
		replace ppe_enf=${supp_ppe_enf}*(nenf+nenfmaj)/2 if ya_ppe>=${seuil_ppe_min} & ya_ppe_pt<=${seuil_ppe_max} & marie==1 & (ya_ppe_conj>=${seuil_ppe_min} | ya_ppe_conj<=${seuil_ppe_max})
		replace ppe_enf=${supp_ppe_enf} if ya_ppe>=${seuil_ppe_min} & ya_ppe_pt>=${seuil_ppe_max} & ya_ppe_pt<=${seuil_ppe_max_coup} & marie==1 & ya_ppe_conj<${seuil_ppe_min} 

		* ppe pour le conjoint d'un couple marié ou pacsé
		gen ppe_enf_conj=0
		replace ppe_enf_conj=${supp_ppe_enf}*(nenf+nenfmaj) if ya_ppe_conj>=${seuil_ppe_min} & ya_ppe_conj<=${seuil_ppe_max} & pac==0 & (ya_ppe_pt<${seuil_ppe_min} | ya_ppe_pt>${seuil_ppe_max}) & marie== 1
		replace ppe_enf_conj= ${supp_ppe_enf}*(nenf+nenfmaj)/2 if ya_ppe_conj>=${seuil_ppe_min} & ya_ppe_conj<=${seuil_ppe_max} & marie==1 & (ya_ppe_pt>=${seuil_ppe_min} | ya_ppe_pt<=$seuil_ppe_max)
		replace ppe_enf_conj=${supp_ppe_enf} if ya_ppe_conj>=${seuil_ppe_min} & ya_ppe_conj>=${seuil_ppe_max} & ya_ppe_conj<=${seuil_ppe_max_coup} & marie==1 & ya_ppe_pt<$seuil_ppe_min 

	/**** phase 7-5: supplément parent isolé */
		replace ppe_enf=ppe_enf+${supp_ppe_enf} if seul_enf_irpp==1 & ya_ppe>=${seuil_ppe_min} & ya_ppe_pt<=${seuil_ppe_max}
		replace ppe_enf=2*${supp_ppe_enf} if seul_enf_irpp==1 & ya_ppe>=${seuil_ppe_min} & ya_ppe_pt>${seuil_ppe_max} & ya_ppe_pt<=${seuil_ppe_max_coup}

	/**** phase 7-6: proratisation et majoration pour temps partiel */
		replace ppe=ppe*nbh/${htp} if nbh<${htp}
		gen ppe_tot=0
		replace ppe_tot = ppe+ppe_enf+sup_ppe
		
		gen ppe_brut =0
		replace ppe_brut = ppe_tot
		replace ppe_brut = ppe_brut+${maj_ppe_tp}*ppe if nbh<${htp}/2 & ${annee_sim} > 2001
		replace ppe_brut = (1-${maj_ppe_tp})*ppe+${maj_ppe_tp}*ppe*${htp}/nbh if nbh>=${htp}/2 & nbh<${htp} & ${annee_sim} > 2001
		
		* pour le conjoint
		 gen ppe_brut_conj = 0
		 replace ppe_brut_conj = ppe_conj + sup_ppe_conj + ppe_enf_conj
	  
		*pour le foyer fiscal
		gen ppe_brut_foy = 0
		replace ppe_brut_foy = ppe_brut_conj + ppe_brut
		  
	/**** phase 7-7: plafonnement par rapport au rfr du foyer */
		replace ppe_brut=0 if (rfr_irpp_foy>${seuil_rfr_ppe}+${seuil_rfr_ppe_enf}*(nbp-1) & nbp0==1) | (rfr_irpp_foy>${seuil_rfr_ppe_coup}+${seuil_rfr_ppe_enf}*(nbp-2) & nbp0==2)
		replace ppe=0 if (rfr_irpp_foy>${seuil_rfr_ppe}+${seuil_rfr_ppe_enf}*(nbp-1) & nbp0==1) | (rfr_irpp_foy>${seuil_rfr_ppe_coup}+${seuil_rfr_ppe_enf}*(nbp-2) & nbp0==2)
		replace ppe_enf=0 if (rfr_irpp_foy>${seuil_rfr_ppe}+${seuil_rfr_ppe_enf}*(nbp-1) & nbp0==1) | (rfr_irpp_foy>${seuil_rfr_ppe_coup}+${seuil_rfr_ppe_enf}*(nbp-2) & nbp0==2)
		replace ppe_tot=0 if (rfr_irpp_foy>${seuil_rfr_ppe}+${seuil_rfr_ppe_enf}*(nbp-1) & nbp0==1) | (rfr_irpp_foy>${seuil_rfr_ppe_coup}+${seuil_rfr_ppe_enf}*(nbp-2) & nbp0==2)
		replace sup_ppe = 0 if (rfr_irpp_foy>${seuil_rfr_ppe}+${seuil_rfr_ppe_enf}*(nbp-1) & nbp0==1) | (rfr_irpp_foy>${seuil_rfr_ppe_coup}+${seuil_rfr_ppe_enf}*(nbp-2) & nbp0==2)
		replace ppe_brut_conj=0 if (rfr_irpp_foy>${seuil_rfr_ppe}+${seuil_rfr_ppe_enf}*(nbp-1) & nbp0==1) | (rfr_irpp_foy>${seuil_rfr_ppe_coup}+${seuil_rfr_ppe_enf}*(nbp-2) & nbp0==2)
		replace ppe_conj =0 if (rfr_irpp_foy>${seuil_rfr_ppe}+${seuil_rfr_ppe_enf}*(nbp-1) & nbp0==1) | (rfr_irpp_foy>${seuil_rfr_ppe_coup}+${seuil_rfr_ppe_enf}*(nbp-2) & nbp0==2)
		replace sup_ppe_conj = 0 if (rfr_irpp_foy>${seuil_rfr_ppe}+${seuil_rfr_ppe_enf}*(nbp-1) & nbp0==1) | (rfr_irpp_foy>${seuil_rfr_ppe_coup}+${seuil_rfr_ppe_enf}*(nbp-2) & nbp0==2)
		replace ppe_enf_conj=0 if (rfr_irpp_foy>${seuil_rfr_ppe}+${seuil_rfr_ppe_enf}*(nbp-1) & nbp0==1) | (rfr_irpp_foy>${seuil_rfr_ppe_coup}+${seuil_rfr_ppe_enf}*(nbp-2) & nbp0==2)
		replace ppe_brut_foy=0 if (rfr_irpp_foy>${seuil_rfr_ppe}+${seuil_rfr_ppe_enf}*(nbp-1) & nbp0==1) | (rfr_irpp_foy>${seuil_rfr_ppe_coup}+${seuil_rfr_ppe_enf}*(nbp-2) & nbp0==2)
	
	/****phase 7-8  Calcul de la PPE net du RSA */
		
		* Note : On déduit de la ppe le RSA 
		
		* Calcul de la PPE nette du RASE (foyer fiscal)
		
		gen ppe_net_foy = 0
		replace ppe_net_foy = max(ppe_brut_foy-rsa_act_foys,0)
		
		* Individualisation de la PPE
		
		gen a = 0
		replace a = ppe_brut/ppe_brut_foy if ppe_brut_foy>0
		gen b = 0 
		replace b = ppe_brut_conj/ppe_brut_foy if ppe_brut_foy>0
		
		gen ppe_net = 0
		replace ppe_net = a*ppe_net_foy if ppe_net_foy > 0
		gen ppe_net_conj = 0
		replace ppe_net_conj = b*ppe_net_foy if ppe_net_foy > 0
		drop a b
		
		gen irpp_net_ppe_foy = 0
		replace irpp_net_ppe_foy = max(0,irpp_tot_foy-ppe_net_foy)
		
		gen ppe_rest_foy = 0
		replace ppe_rest_foy = max(ppe_net_foy-max(irpp_tot_foy,0),0)
	
