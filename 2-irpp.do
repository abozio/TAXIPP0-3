***********************************
/* 1. Calcul du revenu imposable */
***********************************

/* 1.1. Calcul du revenu brut global = somme des revenus catégoriels imposables */ 
**********************************************************************************

* Besoin de variables au niveau du foyer fiscal :
  global variables "chom_irpp pension_irpp frais_prof pens_alim_rec"
	drop pens_alim_rec_foy chom_irpp_* pension_irpp_*
	global exist_foy 0
	global exist_conj 0
	global exist_pac 0
	do "$dofiles\variables foyer fiscal.do"

	*a)Traitements, salaires, pensions et rentes viagères

		*Déduction de l'abattement de 10%
				
			* Calcul des salaires et chomage nets de l'abattement de 10% :
			gen salchom_imp=0
			replace salchom_imp = max(min(sal_irpp+chom_irpp-min(max(${tx_abt_sal}*(sal_irpp+chom_irpp),${min_abtsal}),${max_abtsal}),sal_irpp+chom_irpp-frais_prof),0)
			gen salchom_imp_conj= 0
			replace salchom_imp_conj=max(min(sal_irpp_conj+chom_irpp_conj-min(max(${tx_abt_sal}*(sal_irpp_conj+chom_irpp_conj),${min_abtsal}),${max_abtsal}),sal_irpp_conj+chom_irpp_conj-frais_prof_conj),0)
			gen salchom_imp_pac = 0
			replace  salchom_imp_pac = max(sal_irpp_pac+chom_irpp_pac-min(max(${tx_abt_sal}*(sal_irpp_pac+chom_irpp_pac),nenfmaj*${min_abtsal}),nenfmaj*${max_abtsal}),0)

			* Calcul de la réduction au titre de l'abattement de 10% pour les pensions de retraite et alimentaires imposables :

			gen reduc_imp = max(${tx_abt_sal}*(pension_irpp+pens_alim_rec),${min_abtpen})
			gen reduc_imp_conj = max(${tx_abt_sal}*(pension_irpp_conj+pens_alim_rec_conj),${min_abtpen})
			gen reduc_imp_pac = max(${tx_abt_sal}*(pension_irpp_pac+pens_alim_rec_pac),nenfmaj*${min_abtpen})
			gen reduc_tot = min(reduc_imp + reduc_imp_conj + reduc_imp_pac, ${max_abtpen})

			gen tot = reduc_imp+reduc_imp_conj+reduc_imp_pac
			replace reduc_imp = reduc_imp/tot*reduc_tot
			replace reduc_imp_conj  = reduc_imp_conj/tot*reduc_tot
			replace reduc_imp_pac = reduc_imp_pac/tot*reduc_tot
			drop tot
							
			* Salaires, chômage et pensions nets de l'abattement de 10% :

			gen rbg = salchom_imp + max(0, pension_irpp + pens_alim_rec - reduc_imp)
			gen rbg_conj = salchom_imp_conj + max(0, pension_irpp_conj + pens_alim_rec_conj - reduc_imp_conj)
			gen rbg_pac = salchom_imp_pac + max(0, pension_irpp_pac + pens_alim_rec_pac - reduc_imp_pac)


		*Déduction de l'abattement de 20%
		if ${annee_sim} < 2006 {
			replace rbg = max(rbg-min(${tx_ded_sal}* rbg,${max_abt_dedsal}) , 0)
			replace rbg_conj = max(rbg_conj-min(${tx_ded_sal}* rbg_conj,${max_abt_dedsal}) , 0)
			replace rbg_pac = max(rbg_pac-min(${tx_ded_sal}* rbg_pac,nenfmaj*${max_abt_dedsal}) , 0)
			}

		* Variables nécéssaire au calcul du rfr ind et de la décomposition de l'impôt sur le revenu par types de revenus (rimp_tp, rimp_sec)
		gen rimp_tp = sal_irpp/(sal_irpp+chom_irpp+pension_irpp+pens_alim_rec)*rbg
		gen rimp_sec =(sal_irpp+chom_irpp+pension_irpp)/(sal_irpp+chom_irpp+pension_irpp+pens_alim_rec)*rbg
		gen rbg_foy = rbg + rbg_conj + rbg_pac
		
		* redécomposition de rbg_foy en pensions et salaires imposables
		gen pension_imp_foy = max(0, pension_irpp + pens_alim_rec - reduc_imp) + max(0, pension_irpp_conj + pens_alim_rec_conj - reduc_imp_conj) + max(0, pension_irpp_pac + pens_alim_rec_pac - reduc_imp_pac)
		gen salchom_imp_foy = salchom_imp + salchom_imp_conj + salchom_imp_pac
		drop reduc_imp reduc_imp_conj reduc_imp_pac reduc_tot

		gen tot = pension_imp_foy+salchom_imp_foy
		replace pension_imp_foy = pension_imp_foy/tot *rbg_foy if tot ~= 0
		replace salchom_imp_foy = salchom_imp_foy/tot * rbg_foy if tot ~= 0
		drop tot

	*b) Revenus non salariés imposables
	gen nonsal_imp = nonsal_irpp - nonsalexo_irpp
	gen nonsal_imp_foy = nonsal_irpp_foy - nonsalexo_irpp_foy

	*c) Revenus fonciers imposables
	gen rfon_imp_foy=(1-${abt_micro_fon})*rfon_micro_irpp_foy +cond(rfon_normal_irpp_foy-rfon_defcat_foy>0,cond(rfon_normal_irpp_foy-rfon_defcat_foy-rfon_defglo_foy>0,max(rfon_normal_irpp_foy-rfon_defcat_foy-rfon_defglo_foy-rfon_defcat_ant_foy,0),rfon_normal_irpp_foy-rfon_defcat_foy-rfon_defglo_foy), -min(${plaf_def_fonc},rfon_defglo_foy) )

	*d) Revenus financiers imposables
	gen rfin_av_imp_foy = max(rfin_av_bar_irpp_foy-$abt_av*(nadul-nenfmaj),0)
	gen rfin_imp_foy=max(rfin_av_bar_irpp_foy-$abt_av*(nadul-nenfmaj),0)
	replace rfin_imp_foy=rfin_imp_foy+max(rfin_div_bar_irpp_foy*(1-$tx_abt_rcm)-$abt_rcm*(nadul-nenfmaj),0)
	replace rfin_imp_foy=rfin_imp_foy+rfin_int_bar_irpp_foy

	*e) Calcul du revenu brut global
	gen rbg_irpp_foy=max(0,salchom_imp_foy+pension_imp_foy+nonsal_imp_foy+rfon_imp_foy+rfin_imp_foy)

	*f) Déficits globaux années antérieures
	replace rbg_irpp_foy=max(rbg_irpp_foy-defglo_ant_foy,0)

/* 1.2. Calcul du revenu imposable = revenu brut global - charges déductibles */
********************************************************************************
	
/* Besoin de calculer certaines variables d'abord : */
	
	/* Création des revenus au niveau du foyer au sens de l'irpp */
	
	global liste "sal_irpp nonsal_irpp pension_irpp chom_irpp nonsalexo_irpp rfon_normal_irpp rfon_micro_irpp rfin_div_bar_irpp rfin_int_bar_irpp rfin_av_bar_irpp rfin_div_pl_irpp rfin_int_pl_irpp rfin_av_pl_irpp rfin_pv_normal_irpp rfin_pv_options1_irpp rfin_pv_options2_irpp rfin_pv_exo_irpp rfin_pv_pro_irpp rfin_pv_pro_exo_irpp rfin_pea_exo_irpp ded_epar_ret pens_alim_rec pens_alim_ver rfon_defcat rfon_defglo rfon_defcat_ant"
	foreach var in $liste {
		drop `var'_foy
		bys id_foyf : egen `var'_foy = total(`var')
		}
	/* Démarche inverse : création de valeurs individuelles à partir des valeurs au niveau du foyer */
	drop defglo_ant
	gen defglo_ant=0
	replace defglo_ant = defglo_ant_foy/(1+marie) if pac~=1
	
	* Constitution des variables synthétiques de revenu financiers imposables à l'IRPP 
	*gen rfon_irpp_foy = rfon_normal_irpp_foy + rfon_micro_irpp_foy
	gen rfin_bar_irpp_foy  = rfin_div_bar_irpp_foy + rfin_int_bar_irpp_foy + rfin_av_bar_irpp_foy
	gen rfin_pl_irpp_foy   = rfin_div_pl_irpp_foy + rfin_int_pl_irpp_foy + rfin_av_pl_irpp_foy
	*gen rfin_pv_irpp_foy   = rfin_pv_normal_irpp_foy + rfin_pv_options1_irpp_foy + rfin_pv_options2_irpp_foy + rfin_pv_exo_irpp_foy + rfin_pv_pro_irpp_foy + rfin_pv_pro_exo_irpp_foy
	gen rfin_irpp_foy      = rfin_bar_irpp_foy + rfin_pl_irpp_foy + rfin_pv_irpp_foy

	/** csg déductible sur revenus du capital */
	/*QL: il manque la variable "rfin_pl_foy", qu'suppose être "rfin_pl_irpp_foy". A terme, il faudra s'en assurer mais pour l'instant cela ne change pas grand chose à ce qu'on veut avoir  */
		
	gen csg_yk_ded_foy=${tx_csg_ded_rk_patr}*(rfin_bar_irpp_foy+rfon_irpp_foy)
	*+rfin_pl_foy*cond(${annee_sim} > 2012,1,0))
	gen rimp_irpp_foy=max(rbg_irpp_foy-csg_yk_ded_foy,0)

	/** pensions alimentaires versées */
	replace rimp_irpp_foy=max(rimp_irpp_foy-min(pens_alim_ver_foy,${plaf_penalim}),0)
	gen pens_alim_foy = 0
	replace pens_alim_foy =min(pens_alim_ver_foy,${plaf_penalim})

	/** déductions épargne retraite */
	replace rimp_irpp_foy=max(rimp_irpp_foy-ded_epar_ret_foy,0)

	/** abattement spécial personnes âgées */
	gen abt_pers_age_foy= ${abt_pers_age}*(cond(age>=65,1,0)+marie*cond(age_conj>=65,1,0))*(cond(rimp_irpp_foy<=${plaf_pers_age1},1,0)+0.5*cond(rimp_irpp_foy>${plaf_pers_age1},cond(rimp_irpp_foy<=${plaf_pers_age2},1,0),0))
	replace abt_pers_age_foy = min(abt_pers_age_foy,rimp_irpp_foy)
	replace rimp_irpp_foy=max(rimp_irpp_foy-abt_pers_age_foy,0)

/* 1.3. Revenu fiscal de référence (RFR) */
*******************************************

* NOTE: RFR = revenu imposable + revenus PL et PV + certaines déductions
	
	drop rfr_irpp_foy
	* Au niveau foyer fiscal
	gen rfr_irpp_foy = rimp_irpp_foy + rfin_pv_irpp_foy + rfin_pl_irpp_foy + abt_pers_age_foy + nonsalexo_irpp_foy
		
	* Au niveau individuel
	replace rbg = rbg + nonsal_irpp 
	replace rbg = rbg + (rfon_imp_foy+rfin_imp_foy)/(1+marie) if pac~= 1
	replace rbg_foy= max(0,rbg_foy+nonsal_irpp_foy+rfon_imp_foy+rfin_imp_foy)
		
	gen rbg2 = max(0,rbg - rbg/rbg_foy*(defglo_ant_foy+ded_epar_ret_foy)-min(pens_alim_ver,${plaf_penalim}))
	replace rbg2 = max(0,rbg2-csg_yk_ded_foy/2) if pac~= 1
		
	gen rfr_irpp = rbg2
	replace rfr_irpp = rfr_irpp + (rfin_pv_irpp_foy+rfin_pl_irpp_foy)/(1+marie) if pac~= 1
	drop rbg  rbg2 

	*Calcul des revenus selon définition revenus primaires (rimp_tp) /revenus secondaires (rimp_sec)
		
	/*gen rbg3 = max(0,rbg_foy-nonsalexo_irpp_foy)
	
	replace rimp_tp = rimp_tp + (nonsal_irpp-nonsalexo_irpp)
	replace rimp_tp = max(0,rimp_tp + (rfon_imp_foy+rfin_imp_foy)/(1+marie)) if pac ~= 1
	replace rimp_tp = max(0,rimp_tp-rimp_tp/rbg3*(defglo_ant_foy+ded_epar_ret_foy)-min(pens_alim_ver,${plaf_penalim})-min(abt_pers_age_foy, ${abt_pers_age}))
	replace rimp_tp = max(0,rimp_tp-csg_yk_ded_foy/2) if pac~=1

	replace rimp_sec = rimp_sec +  (nonsal_irpp-nonsalexo_irpp)
	replace rimp_sec = max(0,rimp_sec + (rfon_imp_foy+rfin_imp_foy)/(1+marie)) if pac ~= 1
	replace rimp_sec = max(0,rimp_sec-rimp_sec/rbg3*(defglo_ant_foy+ded_epar_ret_foy)-min(pens_alim_ver,${plaf_penalim})-min(abt_pers_age_foy, ${abt_pers_age}))
	replace rimp_sec = max(0,rimp_sec-csg_yk_ded_foy/2) if pac~=1
		
	drop rbg3 rbg_foy */

******************************************************************
/* 2. Calcul de l'impôt brut (quotient familal, barème, décote) */
******************************************************************
		
		/* 2.1. Programme du calcul de l'IR */
		******************************************
		global sup = ${ntranche} +1
		global tranche$sup = .
		cap program drop baremeir
		program baremeir
		args r_IR irppx 
		g base=`r_IR'
		g `irppx'=0
		g i0=0
		forval n=1/${ntranche} {
		local p=`n'-1
		local m=`n'+1
		replace `irppx'= (${txmarg`n'}*(base-${tranche`n'})+i`p') if (base>= ${tranche`n'}) & (base < ${tranche`m'}) 
		g i`n'=i`p'+${txmarg`n'}*(${tranche`m'}-${tranche`n'})
		}
		drop base
		drop i0-i${ntranche}
		end

		/* 2.2. Calcul du nombre de parts de quotient familial */
		*********************************************************

		gen nbp0=nadul-nenfmaj
		gen nbp_enf=0.5*cond(nenf+nenfmaj>=1,1,0)+0.5*cond(nenf+nenfmaj>=2,1,0)+1*cond(nenf+nenfmaj>=3,1,0)*(nenf+nenfmaj-2)
		gen nbp_seul=0.5*cond(seul_enf_irpp==1,1,cond(seul_enfmaj_irpp==1,1,0))
		replace nbp=nbp0+nbp_enf+nbp_seul

		/* 2.3. Calcul de l'impôt barème avec et sans enfants */
		********************************************************

		/**impôt barème sans enfants*/
		gen rpp0_foy=rimp_irpp_foy/nbp0
		baremeir rpp0_foy irpp_bar0_foy
		replace irpp_bar0_foy=nbp0*irpp_bar0_foy
		
		/**impôt barème avec enfants*/
		gen rpp_foy=rimp_irpp_foy/nbp
		baremeir rpp_foy irpp_bar_foy
		replace irpp_bar_foy=nbp*irpp_bar_foy

		/* 2.4. Application du plafonnement des effets du quotient familial */
		**********************************************************************

		gen reduc_qf0_foy=irpp_bar0_foy-irpp_bar_foy
		gen plaf_qf_foy=${plaf_qf}*(nbp-nbp0)*2
		replace plaf_qf_foy=${plaf_qf_parentisole}+${plaf_qf}*(nbp-nbp0-1)*2 if seul_enf_irpp==1
		replace plaf_qf_foy=${plaf_qf_persseule} if seul_enfmaj_irpp==1
		gen reduc_qf_foy=min(reduc_qf0_foy,plaf_qf_foy)*cond(seul_enfmaj_irpp==1,0,1)
		gen reduc_enfmaj_foy=min(reduc_qf0_foy,plaf_qf_foy)*cond(seul_enfmaj_irpp==1,1,0)
				
		/* 2.5. Autres réductions de droits simples (demi part supplémentaires etc.) */
		*******************************************************************************
		gen irpp_ds_foy=irpp_bar0_foy-reduc_qf_foy-reduc_enfmaj_foy
		replace irpp_ds_foy=irpp_ds_foy-reduc_ds_foy
		
		/* 2.6. Application de la décote */
		***********************************
		gen decote_irpp_foy=0
		replace decote_irpp_foy=min(irpp_ds_foy,(${param_decote}-irpp_ds_foy/cond(${annee_sim}>1999,2,1))) if irpp_ds_foy<${param_decote}
		gen irpp_brut_foy=max(irpp_ds_foy-decote_irpp_foy,0)

****************************************************************
/* 3. Calcul de l'impôt net (réductions d'impôt, plus-values) */
****************************************************************
	
	/* 3.1. Calcul des réductions d'impôts */
	***********************************
	
	* a) Plafonnement des niches fiscales :
	if ${annee_sim}> 2009 {
		replace reduc_irpp_foy = min(${plaf_nich}+${tx_nich}*rimp_irpp_foy, reduc_irpp_foy)
		egen masse_reduc2 = sum(decl*pondv*reduc_irpp_foy/1000000000)
		gen f = 0
		replace f=1 if reduc_irpp_foy < ${plaf_nich}+${tx_nich}*rimp_irpp_foy
		egen masse_reduc3 = sum(f*decl*pondv*reduc_irpp_foy/1000000000) 
		replace reduc_irpp_foy = reduc_irpp_foy*(masse_reduc3+${masse_reduc_irpp}-masse_reduc2)/masse_reduc3 if f == 1
		drop masse_reduc2 masse_reduc3 f
		}

		* b) Réductions d'impôts (Cas général)
		gen reduc_irpp_foy_tot = min(irpp_brut_foy,reduc_irpp_foy)
	
		* c) Réductions d'impôt spécifiques : 
		
			* Habitation principale : la variable "reduc_hab_foy" existe déjà
			
			* Intérêts d'emprunt : la variable "reduc_int_foy" existe déjà
			
			* Crédit d'impôt exceptionnel en faveur des contribuables modestes en 2009 d'1 milliard :
			gen credit_excep_foy = 0
			if ${annee_sim} == 2008 {
				replace credit_excep_foy = 2/3*irpp_bar_foy if rpp_foy < ${tranche3}
				replace credit_excep_foy = -0.2702*rpp_foy+3370.22 if rpp_foy > ${tranche3} & rpp_foy < 12475
				sum credit_excep_foy [w=pondv] if decl==1
				global r =r(sum)/1000000000
				replace credit_excep_foy = credit_excep_foy*1/$r
				}
				
			* Calcul du crédit d'impôt sur les dividendes pour la période 2005-2010 (avant 2005 et après 2010 plaf_creditRCM = 0 donc credit_div = 0) :
			gen credit_div_foy = 0
			replace credit_div_foy = min(0.5*rfin_div_bar_irpp_foy,${plaf_creditRCM}*(nadul-nenfmaj))
				
		* d) Réductions d'impôts totales :
		replace reduc_irpp_foy_tot = reduc_irpp_foy_tot + credit_div_foy + credit_excep_foy + reduc_int_foy + reduc_hab_foy
		
	/* 3.2. Calcul des Plus-values */
	**********************************
		
		* a) Prise en compte de la suppression du seuil d'imposition des plus values :
		if $annee_sim >= 2011 {
			gen r_fin_tot_foy = 0
			replace r_fin_tot_foy = rfin_irpp_foy + rfin_pl_irpp_foy if rfin_pv_normal_irpp_foy == 0
			egen masse_r_fin_tot = sum(r_fin_tot_foy*decl*pondv)
			replace rfin_pv_normal_irpp_foy = r_fin_tot_foy/masse_r_fin_tot*${sup_seuil_pv} if r_fin_tot_foy> 0
			replace rfin_pv_irpp_foy = rfin_pv_irpp_foy + rfin_pv_normal_irpp_foy if r_fin_tot_foy> 0
			drop  r_fin_tot_foy masse_r_fin_tot
			}
			
		* b) Imposition des plus-values :
		gen irpp_pv_foy=${tx_pv}*rfin_pv_normal_irpp_foy+${tx_pv1}*rfin_pv_options1_irpp_foy+${tx_pv2}*rfin_pv_options2_irpp_foy+${tx_pv_pro}*rfin_pv_pro_irpp_foy

	/* 3.3. Impôt total */
	**********************
		* a) Impôt total
		
		replace irpp_net_foy = irpp_brut_foy-reduc_irpp_foy_tot
		gen irpp_tot_foy = irpp_net_foy+irpp_pv_foy
		 
		* b) Montant d'impôts qui sera non-comptabilisé dans le calcul du bouclier fiscal = 1 point de pv et 1 point du tx marginal supérieur de l'IR
		gen irpp_foy_bouclier_cap = 0
		gen irpp_foy_bouclier_trav = 0
		gen irpp_foy_bouclier_remp = 0
		
		if ${annee_sim} == 2010 {
			* Plus-values
			replace irpp_foy_bouclier_cap = 0.01*(rfin_pv_normal_irpp_foy+rfin_pv_pro_irpp_foy+rfin_pv_options1_irpp_foy) 
		
			* Taux marginal IR
			gen a = 0
			replace a = 0.01*max(0,rpp_foy-${tranche5})*nbp 
			
			replace rfon_imp_foy=max(rfon_imp_foy,0)
			replace nonsal_imp_foy=max(nonsal_imp_foy,0)
			gen rbc_irpp_foy=pension_imp_foy+salchom_imp_foy +nonsal_imp_foy+rfon_imp_foy+rfin_imp_foy
			
			replace irpp_foy_bouclier_trav = a*(salchom_imp_foy/rbc_irpp_foy)*(sal_irpp+sal_irpp_conj+sal_irpp_pac)/(sal_irpp+sal_irpp_conj+sal_irpp_pac+chom_irpp+chom_irpp_conj+chom_irpp_pac) + a*nonsal_imp_foy/rbc_irpp_foy
			replace irpp_foy_bouclier_remp = a*(salchom_imp_foy/rbc_irpp_foy)*(chom_irpp+chom_irpp_conj+chom_irpp_pac)/(sal_irpp+sal_irpp_conj+sal_irpp_pac+chom_irpp+chom_irpp_conj+chom_irpp_pac) + a*pension_imp_foy/rbc_irpp_foy
			replace irpp_foy_bouclier_cap = irpp_foy_bouclier_cap + a*(rfon_imp_foy+rfin_imp_foy)/rbc_irpp_foy
			drop rbc_irpp_foy a
			
			replace irpp_foy_bouclier_trav =0 if irpp_foy_bouclier_trav==.
			replace irpp_foy_bouclier_cap =0 if irpp_foy_bouclier_cap==.
			replace irpp_foy_bouclier_remp =0 if irpp_foy_bouclier_remp==.
			}
			
****************************************************************
/* 4. Réduction d'impôt pour changement de statut matrimonial */
****************************************************************
* Supprimé à partir de l'imposition des revenus de 2010
		gen reduc_double_dec_foy=0
		if ${annee_sim} <2010 {
		/********phase 4-1: calcul de l'impôt correspondant à la première déclaration*/
				
				/***phase 4-1-1: barème*/
				gen rpp1_foy=p1*rpp_foy
				baremeir rpp1_foy irpp_bar1_foy
				replace irpp_bar1_foy=nbp*irpp_bar1_foy
				/***phase 4-1-2: plafonnement du quotient familial*/
				replace rpp0_foy=p1*rpp0_foy
				baremeir rpp0_foy irpp_bar10_foy
				replace irpp_bar10_foy=nbp0*irpp_bar10_foy
				gen reduc_qf1_foy=irpp_bar10_foy-irpp_bar1_foy
				gen reduc_qf_plaf1_foy=min(reduc_qf1_foy,plaf_qf_foy)
				gen irpp_ds1_foy=irpp_bar10_foy-reduc_qf_plaf1_foy
				/***phase 4-1-3: décôte*/
				gen decote_irpp1_foy=0
				replace decote_irpp1_foy=min(irpp_ds1_foy,(${param_decote}-irpp_ds1_foy)/cond(${annee_sim}>1999,2,1)) if irpp_ds1_foy<${param_decote}
				gen irpp_brut1_foy=max(irpp_ds1_foy-decote_irpp1_foy,0)
		
		/********phase 4-2: calcul de l'impôt correspondant à la seconde déclaration*/
				
				/***phase 4-2-1: nombre de parts de la seconde déclaration*/
				gen nbp02=nbp0
				replace nbp02=1 if nbp0==2 & change==1
				replace nbp02=2 if nbp0==1 & change==1
				gen nbp2=nbp-nbp0+nbp02
				/***phase 4-2-2: revenu imposable de la seconde déclaration*/
				gen rimp2_foy=(1-p1)*rimp_irpp_foy
				replace rimp2_foy=(1-p1)*rimp_irpp_foy/2 if nbp0==2 & change==1
				replace rimp2_foy=(1-p1)*rimp_irpp_foy*2 if nbp0==1 & change==1
				/***phase 4-2-3: barème*/
				gen rpp2_foy=rimp2_foy/nbp2
				baremeir rpp2_foy irpp_bar2_foy
				replace irpp_bar2_foy=nbp2*irpp_bar2_foy
				/***phase 4-2-4: plafonnement du quotient familial*/
				replace rpp0_foy=rimp2_foy/nbp02
				baremeir rpp0_foy irpp_bar20_foy
				replace irpp_bar20_foy=nbp02*irpp_bar20_foy
				gen reduc_qf2_foy=irpp_bar20_foy-irpp_bar2_foy
				gen reduc_qf_plaf2_foy=min(reduc_qf2_foy,plaf_qf_foy)
				gen irpp_ds2_foy=irpp_bar20_foy-reduc_qf_plaf2_foy
				/***phase 4-2-5: décôte*/
				gen decote_irpp2_foy=0
				replace decote_irpp2_foy=min(irpp_ds2_foy,(${param_decote}-irpp_ds2_foy)/cond(${annee_sim}>1999,2,1)) if irpp_ds2_foy<${param_decote}
				gen irpp_brut2_foy=max(irpp_ds2_foy-decote_irpp2_foy,0)
		
		/********phase 4-3: calcul de la réduction d'impôt correspondante*/ 
		replace reduc_double_dec_foy=irpp_brut_foy-irpp_brut1_foy-irpp_brut2_foy*2 if nbp0==2 & change==1
		replace reduc_double_dec_foy=irpp_brut_foy-irpp_brut1_foy-irpp_brut2_foy/2 if nbp0==1 & change==1
		replace reduc_double_dec_foy=max(reduc_double_dec_foy,0)

		/********phase 4-4: calcul du nouvel impôt net*/

			*Réductions d'impôts		
			replace reduc_irpp_foy_tot = min(irpp_brut_foy,reduc_irpp_foy+${reduc_doub_dec}*reduc_double_dec_foy) + credit_div_foy + credit_excep_foy + reduc_int_foy + reduc_hab_foy
				
			* impôt total
			replace irpp_net_foy=irpp_brut_foy-reduc_irpp_foy_tot
			replace irpp_tot_foy=irpp_net_foy+irpp_pv_foy
			
			}

******************************************************************************************
/* 5. Calcul d'un IRPP catégoriel (au niveau individuel et du foyer fiscal)              */
******************************************************************************************

	/*	/*******phase 5-1 : calcul d'un irpp catégoriel au niveau du foyer fiscal */

		replace rfon_imp_foy=max(rfon_imp_foy,0)
		replace nonsal_imp_foy=max(nonsal_imp_foy,0)
		
		gen rbc_irpp_foy=pension_imp_foy+salchom_imp_foy +nonsal_imp_foy+rfon_imp_foy+rfin_imp_foy+rfin_pl_foy_imp

		gen irpp_cat_foy=irpp_net_foy
		
		gen irpp_sal_foy=irpp_cat_foy*(salchom_imp_foy/rbc_irpp_foy)*(sal_irpp+sal_irpp_conj+sal_irpp_pac)/(sal_irpp+sal_irpp_conj+sal_irpp_pac+chom_irpp+chom_irpp_conj+chom_irpp_pac)
		replace irpp_sal_foy=0 if rbc_irpp_foy==0 | sal_irpp+sal_irpp_conj+sal_irpp_pac+chom_irpp+chom_irpp_conj+chom_irpp_pac ==0
		
		gen irpp_chom_foy=irpp_cat_foy*(salchom_imp_foy/rbc_irpp_foy)*(chom_irpp+chom_irpp_conj+chom_irpp_pac)/(sal_irpp+sal_irpp_conj+sal_irpp_pac+chom_irpp+chom_irpp_conj+chom_irpp_pac)
		replace irpp_chom_foy=0 if rbc_irpp_foy==0 | (sal_irpp+sal_irpp_conj+sal_irpp_pac+chom_irpp+chom_irpp_conj+chom_irpp_pac) ==0
		
		gen irpp_pens_foy=irpp_cat_foy*(pension_imp_foy/rbc_irpp_foy)*(pension_irpp_foy)/(pension_irpp_foy+pens_alim_rec+pens_alim_rec_conj+pens_alim_rec_pac)
		replace irpp_pens_foy=0 if rbc_irpp_foy==0 | pension_irpp_foy+pens_alim_rec+pens_alim_rec_conj+pens_alim_rec_pac==0
		
		gen irpp_alim_foy=irpp_cat_foy*(pension_imp_foy/rbc_irpp_foy)*(pens_alim_rec+pens_alim_rec_conj+pens_alim_rec_pac)/(pension_irpp_foy+pens_alim_rec+pens_alim_rec_conj+pens_alim_rec_pac)
		replace irpp_alim_foy=0 if rbc_irpp_foy==0 | pension_irpp_foy+pens_alim_rec+pens_alim_rec_conj+pens_alim_rec_pac==0
		
		gen irpp_nonsal_foy=irpp_cat_foy*(nonsal_imp_foy/rbc_irpp_foy)
		replace irpp_nonsal_foy=0 if rbc_irpp_foy==0 
		
		gen irpp_rfon_foy=irpp_cat_foy*(rfon_imp_foy/rbc_irpp_foy)
		replace irpp_rfon_foy=0 if rbc_irpp_foy==0 | rfon_irpp_foy==0 | pac==1
		
		gen irpp_rfin_foy=irpp_cat_foy*(rfin_imp_foy+rfin_pl_foy_imp)/rbc_irpp_foy
		replace irpp_rfin_foy=0 if rbc_irpp_foy==0 | rfin_irpp_foy ==0 | pac==1
		
		replace irpp_pv_foy=0 if pac==1

		
		
		/*******phase 5-2 : calcul d'un irpp catégoriel au niveau individuel */
	
		gen irpp_sal=irpp_cat_foy*(salchom_imp_foy/rbc_irpp_foy)*sal_irpp/(sal_irpp+sal_irpp_conj+sal_irpp_pac+chom_irpp+chom_irpp_conj+chom_irpp_pac)
		replace irpp_sal=0 if rbc_irpp_foy==0 | sal_irpp==0
		
		gen irpp_chom=irpp_cat_foy*(salchom_imp_foy/rbc_irpp_foy)*chom_irpp/(sal_irpp+sal_irpp_conj+sal_irpp_pac+chom_irpp+chom_irpp_conj+chom_irpp_pac)
		replace irpp_chom=0 if rbc_irpp_foy==0 | chom_irpp==0
		
		gen irpp_pens=irpp_cat_foy*(pension_imp_foy/rbc_irpp_foy)*(pension_irpp)/(pension_irpp_foy+pens_alim_rec+pens_alim_rec_conj+pens_alim_rec_pac)
		replace irpp_pens=0 if rbc_irpp_foy==0 | pension_irpp==0
		
		gen irpp_alim=irpp_cat_foy*(pension_imp_foy/rbc_irpp_foy)*(pens_alim_rec)/(pension_irpp_foy+pens_alim_rec+pens_alim_rec_conj+pens_alim_rec_pac)
		replace irpp_alim=0 if rbc_irpp_foy==0 | pens_alim_rec==0
		
		gen irpp_nonsal=irpp_cat_foy*(nonsal_imp_foy/rbc_irpp_foy)*nonsal_irpp/nonsal_irpp_foy
		replace irpp_nonsal=0 if rbc_irpp_foy==0 | nonsal_irpp==0
		
		gen irpp_rfon=irpp_cat_foy*(rfon_imp_foy/rbc_irpp_foy)*1/(1+marie)
		replace irpp_rfon=0 if rbc_irpp_foy==0 | rfon_irpp==0 | pac==1
		
		gen irpp_rfin=irpp_cat_foy*(rfin_imp_foy+rfin_pl_foy_imp)/rbc_irpp_foy*1/(1+marie)
		replace irpp_rfin=0 if rbc_irpp_foy==0 | rfin_irpp==0 | pac==1
		
		gen irpp_pv=irpp_pv_foy*1/(1+marie)
		replace irpp_pv=0 if pac==1
		
		drop irpp_cat_foy

		/******** Pour calculer l'importance des réductions d'impôt dans taux d'imposition IR */
			/* Passage qui servait pour le rapport IR
			* revenus du travail
			gen bar0_ya = irpp_bar0_foy*(salchom_imp_foy/rbc_irpp_foy)*(sal_irpp)/(sal_irpp+sal_irpp_conj+sal_irpp_pac+chom_irpp+chom_irpp_conj+chom_irpp_pac) 
			replace bar0_ya = 0 if rbc_irpp_foy == 0 | sal_irpp == 0
			gen bar0_ya2= irpp_bar0_foy*(nonsal_imp_foy/rbc_irpp_foy)*(nonsal_irpp/nonsal_irpp_foy)
			replace bar0_ya2 = 0 if rbc_irpp_foy == 0 | nonsal_irpp == 0
			replace bar0_ya = bar0_ya + bar0_ya2
			drop bar0_ya2
			
			* revenus du capital
			gen bar0_yk = irpp_bar0_foy*(rfon_imp_foy+rfin_imp_foy)/rbc_irpp_foy*1/(1+marie)
			replace bar0_yk = 0 if rbc_irpp_foy == 0 | pac ==1
			
			* revenus de remplacement
			gen bar0_yr = irpp_bar0_foy*(salchom_imp_foy/rbc_irpp_foy)*(chom_irpp)/(sal_irpp+sal_irpp_conj+sal_irpp_pac+chom_irpp+chom_irpp_conj+chom_irpp_pac) 
			replace bar0_yr = 0 if rbc_irpp_foy == 0 | chom_irpp == 0
			gen bar0_yr2 = irpp_bar0_foy*(pension_imp_foy/rbc_irpp_foy)*(pension_irpp)/(pension_irpp_foy+pens_alim_rec+pens_alim_rec_conj+pens_alim_rec_pac)
			replace bar0_yr2 = 0 if rbc_irpp_foy == 0 | pension_irpp == 0
			replace bar0_yr = bar0_yr + bar0_yr2
			drop bar0_yr2
			
			/*******phase 5-2: irpp et qf individuel*/
			gen qf=(reduc_qf_foy+reduc_enfmaj_foy)*(bar0_yr+bar0_yk+bar0_ya)/irpp_bar0_foy
			replace qf = 0 if qf <= 0 | qf == .
			
			gen qf_tp = (reduc_qf_foy+reduc_enfmaj_foy)*(bar0_yk+bar0_ya)/irpp_bar0_foy
			replace qf_tp = 0 if qf_tp <= 0 | qf_tp == .
			gen qf_sec = (reduc_qf_foy+reduc_enfmaj_foy)*(bar0_yr+bar0_yk+bar0_ya)/irpp_bar0_foy
			replace qf_sec = 0 if qf_sec <= 0 | qf_sec == .
			replace reduc_qf_foy = reduc_qf_foy+reduc_enfmaj_foy */

**************************************************
/* 6. Taxe exceptionnelle sur les hauts revenus */
**************************************************
	global list "taxe_HR_foy taxe_HR taxe_HR_trav taxe_HR_cap taxe_HR_remp taxe_HR_foy_trav taxe_HR_foy_cap taxe_HR_foy_remp" 
	foreach var of global list {
	gen `var' = 0
	}
	if ${annee_sim} >= 2011 {
		replace taxe_HR_foy = ${txmarg1_HR}*min(max(0,(rfr_irpp_foy-(nadul-nenfmaj)*${tranche1_HR})),((nadul-nenfmaj)*${tranche2_HR}-(nadul-nenfmaj)*${tranche1_HR}) ) + ${txmarg2_HR}*max(0,(rfr_irpp_foy-(nadul-nenfmaj)*${tranche2_HR})) 
		replace taxe_HR = rfr_irpp/rfr_irpp_foy*taxe_HR_foy if taxe_HR_foy > 0 & rfr_irpp_foy > 0 & pac~=1

		gen y_irpp_ajust = y_irpp
		replace y_irpp_ajust=0.01 if y_irpp==0
		replace taxe_HR_trav = taxe_HR* ya_irpp/(y_irpp_ajust)
		replace taxe_HR_cap  = taxe_HR* yk_irpp/(y_irpp_ajust)
		replace taxe_HR_remp = taxe_HR* yr_irpp/(y_irpp_ajust)

		gen y_irpp_foy_ajust = y_irpp_foy
		replace y_irpp_foy_ajust=0.01 if y_irpp_foy==0
		replace taxe_HR_foy_trav  = taxe_HR_foy *(ya_irpp_foy)/(y_irpp_foy_ajust)
		replace taxe_HR_foy_cap   = taxe_HR_foy *(yk_irpp_foy)/(y_irpp_foy_ajust)
		replace taxe_HR_foy_remp  = taxe_HR_foy *(yr_irpp_foy)/(y_irpp_foy_ajust)
		}

******************************************************************************************************
/* 7. Contribution exceptionnelle de solidarité sur les très hauts revenus d'activité (taxe à 75 %) */
******************************************************************************************************
	global list "taxe_75 taxe_75_foy " 
	foreach var of global list {
	gen `var' = 0
	}
	
	if ${annee_sim} > 2011 {
	global t75 = $tx75-$csg_act-$crds-$txmarg6-$txmarg2_HR
	gen base_t75 = 0
	gen base_t75_conj = 0
	replace base_t75 = sal_irpp-min(${tx_abt_sal}*sal_irpp,${max_abtsal})+nonsal_irpp-nonsalexo_irpp
	replace base_t75_conj= sal_irpp_conj-min(${tx_abt_sal}*sal_irpp_conj,${max_abtsal}) +nonsal_irpp_conj 
	replace taxe_75 = ${t75}*max(0,base_t75-${tranche_tx75})	
	replace taxe_75_foy = taxe_75 + ${t75}*max(0,base_t75_conj-${tranche_tx75})
	gen ff_75 = 0
	replace ff_75 =1 if base_t75-${tranche_tx75} > 0
	}


*/

sort id_indiv id_foyf
