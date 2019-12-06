
clear all
cls
cd "D:\Alejandro\8_Investigaciones\Cálculos diversos\Cálculo de egresados"
global base "D:\Alejandro\1_Bases de datos\ENAHO\Bases anuales"

	* Estandarizando variables en ENAHO
	clear
	forv i = 2004/2018{
	display "`i'"
	u "$base\enaho01a-`i'-300"
	cap tostring p301a1o, replace
	cap tostring p310c1, replace p310c1
	cap decode p310c1 , g(abc_p310c1)
	cap drop p310c1
	cap rename abc_p310c1 p310c1
	save "$base\enaho01a-`i'-300", replace
	}
	
	* Factores de expansión
	tabstat facpob07, by(a_o)
	tabstat factor07, by(a_o)
	replace factor07=facpob07 if a_o=="2012"
	
	tabstat factor07a, by(a_o)	
	replace factor07a=factor07 if inlist(a_o,"2004","2005","2006","2007","2008") | inlist(a_o,"2009","2010","2011","2012","2013","2014")



