/*********************************************************************************/
* TAXIPP 0.3 cotsoc_cal.do                                                        *
*                                                                                 *
*   1. Calcul des cotisations sociales sur les revenus d'activité                 *
*                                                                                 *
* Antoine Bozio 02/2013                                                           *
* Quentin Lafféter 02/2013                                                        *
/*********************************************************************************/


    ***********************************************************************************   
	/** 2. Calage macro des cotisations sociales sur les revenus d'activité			**/
	***********************************************************************************
	
	
		* Masses de CSG et CRDS
		egen masse_csg_sal = total(csg_sal*pondv/1000000000)
		egen masse_crds_sal = total(crds_sal*pondv/1000000000)
		
	
		/* 2.1 Calage des cotisations salariales sur CN (public et privé) */
		***********************************************************************
				
		* Calcul des masses de cotisations salariales
		egen masse_css_sim  = total(css_sim*pondv/1000000000)
		gen assiette_css_cn = masse_css_sim/$masse_css_cn
		
		* Calage des cotisations salariales sur CN (public et privé)
		foreach type in cho ret nco { 
		gen css_`type'_cn = css_`type'/assiette_css_cn
		} 
		gen css_cn = css_sim/assiette_css_cn
		
		/* 2.2 Calage des cotisations patronales du secteur privé (calcul par les masses CN) */
		**************************************************************************************
				
				* 2.2.1 Calage des cotisations patronales secteur privé

					* Calcul des masses de cotisations patronales
					egen masse_csp_priv_sim = total(csp_sim*pondv/1000000000)
					gen assiette_csp_cn = masse_csp_priv_sim/($masse_csp_priv_cn+$masse_csp_priv_exo)
					
					* Calage des cotisations patronales sur CN
					foreach type in sim cho ret nco { 
					gen csp_`type'_cn=csp_`type'/assiette_csp_cn
					}
									
					* Calage des exonérations généralisées de cotisations sociales
					egen masse_csp_priv_exo_sim = total(csp_exo*pondv/1000000000)
					gen assiette_csp_exo        = masse_csp_priv_exo_sim/$masse_csp_priv_exo
					
					replace csp_exo=csp_exo/assiette_csp_exo 
					
					* Total cotisations sociales employeur (calées CN)
					gen csp_cn = csp_sim_cn - csp_exo
		
				
		
		/* 2.3. Impôts sur les salaires et la main d'oeuvre */
		********************************************************
		
		* Calcul des masses et assiettes
		egen masse_tsmo_pr = total(tsmo*(1-public)*pondv/1000000000)
		egen masse_tsmo_pu = total(tsmo*(public)*pondv/1000000000)
		gen assiette_tsmo_pr = masse_tsmo_pr/$masse_ts_pr
		gen assiette_tsmo_pu = masse_tsmo_pu/$masse_ts_pu
		
		* Calage macro par données CN (plus Voies et moyens pour la PEEC)
		gen tsmo_cn = 0
		replace tsmo_cn = tsmo/assiette_tsmo_pr if public==0
		replace tsmo_cn = tsmo/assiette_tsmo_pu if public==1
		
	/* 2.5 Calage des cotisations des non-salariés */
		***************************************************
		
		* Assiette cotisations CN
		egen masse_cs_nonsal_sim=total(cs_nonsal_sim*pondv/1000000000)
		gen assiette_nonsal_cs_cn=$masse_cs_nonsal_cn/masse_cs_nonsal_sim
		
		* Calage des cotisations sur CN
		gen cs_nonsal_cn = cs_nonsal_sim
		replace cs_nonsal_cn     = assiette_nonsal_cs_cn * cs_nonsal_sim 
		gen cs_nonsal_contr_cn   = assiette_nonsal_cs_cn * cs_nonsal_contr
		gen cs_nonsal_noncontr_cn= assiette_nonsal_cs_cn * cs_nonsal_noncontr
		
	/* .1 Salaires super-bruts dans les secteurs public et privé (calés CN) */
		******************************************************************************
		
		gen sal_superbrut_cn = sal_brut_cn + csp_cn + csp_fac + tsmo_cn
		
		
				
	
		
		/** Variables pour l'ensemble des revenus d'activité (salariés et non-salariés) **/
        ***********************************************************************************
        
		* CSG et CRDS
		gen csg_ya = csg_sal + csg_nonsal
		gen crds_ya = crds_sal + crds_nonsal
		
		* Revenu d'activité superbrut (calé sur la CN)
		gen ya_cn = sal_superbrut_cn + nonsal_brut_cn
		
		* Revenu d'activité superbrut - assiette CSG
		gen ya_csg = sal_brut_csg + csp_cn + csp_fac + tsmo_cn + nonsal_brut_csg
		
		* Cotisations sociales totales (calées sur la CN)
		gen cs_cn = css_cn + csp_cn + cs_nonsal_cn
		gen cs_contr_cn    = css_cho_cn + css_ret_cn + csp_ret_cn + csp_cho_cn + cs_nonsal_contr_cn
		gen cs_noncontr_cn = css_nco_cn + csp_nco_cn + cs_nonsal_noncontr_cn
		
		
				
		
		
		/* issu de revcap:

/* Calage de la CSG et des csk */
* A Ajouter dans un dofile de calage
gen csg_patr_foy_avt_cal=csg_patr_foy
gen csg_plac_foy_avt_cal=csg_plac_foy
gen csg_yk_foy_avt_cal=csg_yk_foy
gen csk_patr_foy_avt_cal=csk_patr_foy
gen csk_plac_foy_avt_cal=csk_plac_foy
gen csk_foy_avt_cal=csk_foy
egen masse_csg_yk_sim=total(csg_yk_foy*decl*pondv/1000000000)
replace csg_patr_foy=csg_patr_foy*${masse_csg_yk}/masse_csg_yk_sim
replace csg_plac_foy=csg_plac_foy*${masse_csg_yk}/masse_csg_yk_sim
replace csg_yk_foy=csg_yk_foy*${masse_csg_yk}/masse_csg_yk_sim
egen masse_csk_sim=total(csk_foy*decl*pondv/1000000000)
replace csk_patr_foy=csk_patr_foy*${masse_csk_cn}/masse_csk_sim
replace csk_plac_foy=csk_plac_foy*${masse_csk_cn}/masse_csk_sim
replace csk_foy=csk_foy*${masse_csk_cn}/masse_csk_sim


gen pl_foy_avt_cal=pl_foy
egen masse_pl_sim=sum(pl_foy*decl*pondv/1000000000)
replace pl_foy=pl_foy*${masse_pl_cn}/masse_pl_sim


*/
