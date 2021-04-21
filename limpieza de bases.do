
	clear all
	cls
	cd "E:\9_Trabajo\IEP\1_UNESCO\Indicadores"
	global output "Outputs"
	global bd_enaho "E:\10_BD\ENAHO\Bases anuales"

	* Pool de datos de los módulos de educación, salud y sumaria (2004-2019)
	forv i = 2004/2019 {
	display "`i'"
	u "$bd_enaho\enaho01a-`i'-300", clear
	merge 1:1 conglome vivienda hogar codperso using "$bd_enaho\enaho01a-`i'-400", keepusing(p400a1 p400a2 p400a3 p401*) nogen
	merge m:1 conglome vivienda hogar using "$bd_enaho\sumaria-`i'.dta", keepusing(pobreza mieperho) nogen
	quietly compress
	tempfile input_`i'
	save `input_`i'' 	 
	}
	
	clear
	forv i = 2004/2019{
	display "`i'"
	quietly append using `input_`i''
	}
	
	destring mes a_o, replace
	
	replace factor07a=factora07 if a_o==2019 // Factor de población ajustado a edades
	replace factor07=facpob07 if a_o==2012 // Factores de hogar ajustado al CPV2007
	
	br a_o conglome vivienda hogar codperso factor07a factor07
	
	svyset conglome [pweight=factor07], strata(estrato) vce(linearized) singleunit(missing)	

	* Calculando algunos indicadores y exportándolos
	
		*** Tasa neta de asistencia, educación inicial (% de población con edades 3-5) 

		g edadmarz=. // Edad al 30 de marzo
		replace edadmarz=a_o-p400a3 if p400a2>=1 & p400a2<=3 // Nació entre enero y marzo
		replace edadmarz=a_o-p400a3-1 if p400a2>3 & p400a2<=12 // Nació entre enero y marzo	

		lab list p308a
		g acc_inicial=(p308a==1 & p307==1) if (edadmarz>=3 & edadmarz<=5) & mes>=4
		tab a_o acc_inicial [iw=factor07], nofreq row

		/*
		tab a_o, matrow(rows)
		svy: tab a_o acc_inicial, percent format(%2.1f) row 
		ereturn list
		mat list e(b)
		mat cont = e(b)'
		svy: tab a_o acc_inicial, cv format(%2.1f) row 
		mat list e(b)

		svy: tab a_o acc_inicial, percent format(%2.1f) row 


		mat list e(b) 
		mat cont = e(b)  
		mat list cont  


		svy: tab a_o acc_inicial if acc_inicial==0, percent cv format(%2.1f)  
		mat list e(b) 
		mat cont = e(b)' 
		mat row = e(Row)' 	
		putexcel set filename, modify 
		putexcel A1=("Año") B1=("Sin acceso") C1=("Acceso")
		putexcel A2=matrix(row) B2=matrix(cont)

		matcell(x) matrow(rows)
		*/	

		*ssc install tabout
		svy: tab a_o acc_inicial, percent format(%2.1f) row 
		quietly tabout a_o acc_inicial using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent replace 

		** Controles
		* Discapacidad
		forv i = 1/6 {
			recode p401h`i' (1 = 1 "Sí")(2 = 0 "No"), g(discapacidad_`i')
		}
		egen discapacidad=rowtotal(discapacidad_*)
		replace discapacidad=1 if discapacidad>=1
		svy: tab a_o discapacidad, cv percent format(%2.1f) row

			* Matrícula según por discapacidad
			/*
			svy: tab a_o p308a if discapacidad==1 & p306==1, cv percent format(%2.1f) row 
			quietly tabout a_o p308a if discapacidad==1 & p306==1 using "Outputs\matricula_discapacidad_`c(current_date)'.xls", mi svy percent append

			svy: tab a_o p308a if discapacidad==1 & p307==1, cv percent format(%2.1f) row 
			quietly tabout a_o p308a if discapacidad==1 & p307==1 using "Outputs\matricula_discapacidad_`c(current_date)'.xls", mi svy percent append
			*/

		svy: tab a_o acc_inicial if discapacidad==1, cv percent format(%2.1f) row
		quietly tabout a_o acc_inicial if discapacidad==1 using "Outputs\matricula_discapacidad_`c(current_date)'.xls", mi svy percent append

		svy: tab a_o acc_inicial if discapacidad==0, cv percent format(%2.1f) row

		* Sexo
		svy: tab a_o acc_inicial if p207==1, cv percent format(%2.1f) row // Hombres
		quietly tabout a_o acc_inicial if p207==1 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 

		svy: tab a_o acc_inicial if p207==2, cv percent format(%2.1f) row // Mujeres
		quietly tabout a_o acc_inicial if p207==2 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 

		* Área geográfica de residencia	
		recode estrato (1 2 3 4 5 = 1 Urbano) (6 7 8 = 2 Rural), gen(area)
		lab var area "Área geográfica"
		codebook area

		svy: tab a_o acc_inicial if area==1, cv percent format(%2.1f) row // Urbano
		quietly tabout a_o acc_inicial if area==1 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 
		svy: tab a_o acc_inicial if area==2, cv percent format(%2.1f) row // Rural	
		quietly tabout a_o acc_inicial if area==2 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 

		* Región geográfica (región natural)
		codebook dominio
		recode dominio (1 2 3 = 1 Costa) (4 5 6 = 2 Sierra) (7 = 3 Selva) (8 = 4 "Lima Metropolitana"), gen(region)
		lab var region "Region geográfica"

		svy: tab a_o acc_inicial if region==1, cv percent format(%2.1f) row // Costa
		quietly tabout a_o acc_inicial if region==1 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 
		svy: tab a_o acc_inicial if region==2, cv percent format(%2.1f) row // Sierra
		quietly tabout a_o acc_inicial if region==2 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 	
		svy: tab a_o acc_inicial if region==3, cv percent format(%2.1f) row // Selva
		quietly tabout a_o acc_inicial if region==3 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 
		svy: tab a_o acc_inicial if region==4, cv percent format(%2.1f) row // Lima Metropolitana
		quietly tabout a_o acc_inicial if region==4 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 

		* Tipo de gestión de la IE
		lab list p308d
		svy: tab a_o p308d if acc_inicial==1, cv percent format(%2.1f) row
		quietly tabout a_o p308d if acc_inicial==1 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 

		* Por edades
		svy: tab a_o acc_inicial if edadmarz==3, cv percent format(%2.1f) row // 3 años
		quietly tabout a_o acc_inicial if edadmarz==3 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 	
		svy: tab a_o acc_inicial if edadmarz==4, cv percent format(%2.1f) row // 4 años	
		quietly tabout a_o acc_inicial if edadmarz==4 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 	
		svy: tab a_o acc_inicial if edadmarz==5, cv percent format(%2.1f) row // 5 años	
		quietly tabout a_o acc_inicial if edadmarz==5 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 	

		* Nivel de pobreza
		g factor_personas=mieperho*factor07	
		svyset conglome [pweight=factor_personas], strata(estrato) vce(linearized) singleunit(missing)

		g poor=(inlist(pobreza,1,2))
		label define poor ///
		1 "Pobre" ///
		0 "No pobre"		
		label values poor poor 	

		*svy: tab a_o acc_inicial if poor==1, cv percent format(%2.1f) row // Pobre			
		quietly tabout a_o acc_inicial if poor==1 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 	
		*svy: tab a_o acc_inicial if poor==0, cv percent format(%2.1f) row // No pobre			
		quietly tabout a_o acc_inicial if poor==0 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 	

		* Lengua materna
		lab list p300a
		recode p300a (1 2 3 = 1 "Originaria")(4 = 2 "Castellano")(5 6 7 = 3 "Extranjera")(8 = 4 "Sordo/mudo")(9 = .), g(lengua)

		*svy: tab a_o acc_inicial if lengua==1, cv percent format(%2.1f) row // Originaria
		/*

		Number of strata   =         8                  Number of obs     =      7,688
		Number of PSUs     =     1,400                  Population size   =  1,422,259
								Design df         =      1,392

		-------------------------------
			  |     acc_inicial    
		      año |     0      1  Total
		----------+--------------------
		     2004 |  66.4   33.6  100.0
			  |   4.8    9.6       
			  | 
		     2005 |  57.6   42.4  100.0
			  |   5.7    7.8       
			  | 
		     2006 |  56.9   43.1  100.0
			  |   5.2    6.9       
			  | 
		     2007 |  46.7   53.3  100.0
			  |   5.8    5.1       
			  | 
		     2008 |  44.6   55.4  100.0
			  |   6.5    5.3       
			  | 
		     2009 |  43.4   56.6  100.0
			  |   6.4    4.9       
			  | 
		     2010 |  40.2   59.8  100.0
			  |   7.9    5.3       
			  | 
		     2011 |  41.2   58.8  100.0
			  |   7.2    5.1       
			  | 
		     2012 |  35.2   64.8  100.0
			  |   9.2    5.0       
			  | 
		     2013 |  25.7   74.3  100.0
			  |   9.9    3.4       
			  | 
		     2014 |  15.8   84.2  100.0
			  |  14.6    2.7       
			  | 
		     2015 |  14.3   85.7  100.0
			  |  14.2    2.4       
			  | 
		     2016 |  12.9   87.1  100.0
			  |  19.2    2.9       
			  | 
		     2017 |   9.7   90.3  100.0
			  |  15.9    1.7       
			  | 
		     2018 |   7.7   92.3  100.0
			  |  19.4    1.6       
			  | 
		     2019 |   8.8   91.2  100.0
			  |  18.7    1.8       
			  | 
		    Total |  37.7   62.3  100.0
			  |   3.1    1.9       
		-------------------------------
		  Key:  row percentage
			coefficients of variation of row percentage

		  Pearson:
		    Uncorrected   chi2(15)        = 1129.2039
		    Design-based  F(12.24, 17043.69)=   44.3530   P = 0.0000
		*/
		
		quietly tabout a_o acc_inicial if lengua==1 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 	
		*svy: tab a_o acc_inicial if lengua==2, cv percent format(%2.1f) row // Castellano
		quietly tabout a_o acc_inicial if lengua==2 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 	
		*svy: tab a_o acc_inicial if lengua==3, cv percent format(%2.1f) row // Extranjera
		quietly tabout a_o acc_inicial if lengua==3 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 	
		*svy: tab a_o acc_inicial if lengua==4, cv percent format(%2.1f) row // Sordo/Mudo
		quietly tabout a_o acc_inicial if lengua==4 using "Outputs\indicadores_`c(current_date)'.xls", mi svy percent append 	

		* Nota: Cuidado con los coeficientes de variación! (cv>15)
