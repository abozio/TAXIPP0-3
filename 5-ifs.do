/***************************************************************************************************************/
* TAXIPP 0.3                                                                                                    *
* Simulation de l'ISF au niveau du foyer fiscal                                                                 *
*                                                                                                               *          
* Jonathan Goupille 10/2012                                                                                     *
/***************************************************************************************************************/

/* Application du barème ISF au patrimoine taxable ISF */
  ** programme bareme de l'ISF : 
		
forval x=1/$nbtranches{
	scalar ymin`x'=${seuil`x'_isf}
	}

scalar ymin0=0
global a = ${nbtranches} +1
scalar ymin$a=.
scalar tx0=0
forval x=1/$nbtranches{
	scalar tx`x'=${tx`x'_isf}
	}
				
cap program drop baremeisf
program baremeisf
args KtaxISF isfx 
g base=`KtaxISF'
g `isfx'=0
g i0=0
forval n=1/$nbtranches {
	local p=`n'-1
	local m=`n'+1
	replace `isfx'=(tx`n'*(base-ymin`n')+i`p') if (base>= ymin`n') & (base < ymin`m') 
	g i`n'=i`p'+tx`n'*(ymin`m'-ymin`n')
	}
drop base
drop i0-i$nbtranches 
end

baremeisf actifnetISF ISFbrut
replace ISFbrut = 0 if (actifnetISF < ${seuil2_isf}) & ${annee_sim} >= 2011

* Introduire mécanisme de lissage à partir de 2013

/* Calcul des réductions d'ISF (hors bouclier fiscal et plafonnement 85%) */

	*Reduction d'ISF pour enfants a charge
g ISF=ISFbrut
replace ISF=max(0,ISFbrut-${reduc_isf_enf}*nenf) if nenf>0 & ISFbrut>0
				
	*Imputation des reductions d'ISF pour investissement PME et dons

quietly su ISFbrut [w=pondv]
scalar recettesbrutes=r(sum)/1000000
global reduc=${tot_reduc_pme_isf}+${tot_reduc_dons_isf}
global tx_reduc_isf = ${reduc}/recettesbrutes
replace ISF=max(0,ISF-ISFbrut*${tx_reduc_isf})
quietly so id_indiv

/* Simulation du plafonnement de 85% des revenus (art. 885 V bis du CGI) */

if ${annee_sim} < 2012 | ${annee_sim}> 2012 {	
	g sommeimpots_plafISF = ISF + irpp_tot_foy + pl_foy + tf_foy + th_foy + csg_yk_foy + csk_plac_foy + crds_yk_foy + csg_ya_foy + csg_yr_foy + crds_ya_foy + crds_yr_foy if ISF>0
	g sommerevenus_plafISF= max(0, rfr_irpp_foy+ rfin_int_livret_foy + rfin_int_pel_csg_foy + rfin_av_csg_foy + rfin_div_pea_csg_foy)
	baremeisf ymin4 ISFplaf
	quietly su ISFplaf
	scalar ISFplaf2=r(mean)

	g reduc_plaf85ISF=max(0, min(sommeimpots_plafISF- ${tx_plaf}*(sommerevenus_plafISF), max(${tx_plaf_plaf}*ISF, ${tx_plaf_plaf}*ISFplaf2)))
	g ISF_plaf85=max(0, ISF-reduc_plaf85ISF)

	** prise en compte de la majoration exceptionnelle de 10% sur l'ISF entre 1995 et 1998
	replace ISF_plaf85 = 1.1*ISF_plaf85 if ${annee_sim} < 1999 & ${annee_sim} > 1994 
	}

if ${annee_sim} == 2012 {
	gen ISF_plaf85 = ISF
	gen reduc_plaf85ISF = 0
	gen sommerevenus_plafISF = 0
	gen sommeimpots_plafISF = 0
	}


/* Application du barème ISF au patrimoine economique */

baremeisf k_cn3_foy ISFkeco

/* Calage des recettes/
/*
	* calage des recettes de l'ISF par tranche pour la période 1997-2010 seulement */

if ${annee_sim} <= 2010 {
	forval x=1/$nbtranches {
		quietly su ISF_plaf85 [w=pondv] if tranche ==`x'
		scalar masse_ISF_plaf85`x'=r(sum)/1000000000
		replace ISF_plaf85=ISF_plaf85*${R_isf`x'}/masse_ISF_plaf85`x' if tranche ==`x'
		}
	}

	* calage macro des recettes de l'ISF *

quietly sum ISF_plaf85 [w=pondv] if tranche >0
global masse_ISF_plaf85 =r(sum)/1000000000
replace ISF_plaf85 = ISF_plaf85*${R_isf_tot}/${masse_ISF_plaf85} if tranche > 0
*/

/* Création des variables d'isf au niveau individuel */ 

* Attribution d'un ISF_foy à tous les membres d'un même foyer fiscal
foreach var of varlist  ISF_plaf85 ISF ISFbrut ISFkeco actifnetISF k_cn_foy sommerevenus_plafISF sommeimpots_plafISF ymin tranche  {
	replace `var' =0 if `var'==.
	bys id_foyf : egen `var'_i = max(`var')
	drop `var'
	rename `var'_i `var'
	}

gen k_isf_foy=actifnetISF
gen isf_brut_foy=ISFbrut
gen isf_net_foy=ISF
gen isf_foy=ISF_plaf85
gen isf_keco_foy=ISFkeco

* On renomme les variables
rename sommerevenus_plafISF sommerevenus_plafISF_foy
rename sommeimpots_plafISF sommeimpots_plafISF_foy
rename actifnetISF actifnetISF_foy

/*Pour avoir ce bout du code, il faut renommmer "actifnetISF" en "actifnetISF_ind" dans création_base_yyyy.do car en l'état, on ne l'a pas.*/
/*actifnetISF_foy pose problème, car il vaut 0 si l'individu n'est pas "decl". */
/*gen isf_brut = ISFbrut * actifnetISF_ind / (1+marie) / actifnetISF_foy
gen isf_net = ISF * actifnetISF_ind / (1+marie) / actifnetISF_foy
gen isf = ISF_plaf85 * actifnetISF_ind / (1+marie) / actifnetISF_foy
*gen isf_keco = ISFkeco * k_cn3 / (1+marie) / k_cn3_foy
*drop k_cn3_foy k_cn3
*/

/* JG: pour calculer un ISF au niveau individuel, le mieux est encore de faire tourner l'intégralité du programme individuel
(le calcul du plafonnement crée une discontinuité dans le taux d'imposition)*/

foreach var of varlist isf_foy-sommeimpots_plafISF_foy ymin-tranche {
	replace `var' =0 if `var'==.
	}


/* Création des labels */
*do "$taxipp\Programmes\Labels\label isf(foyer) 0_1.do"
