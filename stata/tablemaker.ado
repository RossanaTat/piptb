/*==================================================
project:       Stata package to manage PovcalNet files and folders
Author:        R.Andres Castaneda 
E-email:       acastanedaa@worldbank.org
url:           https://github.com/randrescastaneda/pcn
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:    29 Jul 2019 - 09:18:01
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/

/*==================================================
0: Program set up
==================================================*/
program define tablemaker, rclass
syntax anything(name=subcmd id="subcommand"),  ///
[                                         ///
			COUNtries(string)                   ///
			Years(numlist)                      ///
			REGions(string)                     ///
			maindir(string)                     ///
			type(string)                        ///
			clear                               ///
			pause                               ///
			vermast(string)                     ///
			veralt(string)                      ///
			*                                   ///
] 
version 15

*---------- conditions
if ("`pause'" == "pause") pause on
else                      pause off


qui {
/*==================================================
	    Dependencies         
==================================================*/
if ("${tm_ssccmd}" == "") {
*--------------- SSC commands
	local cmds missings
	
	noi disp in y "Note: " in w "{cmd:tablemaker} requires the packages below: " /* 
	 */ _n in g "`cmds'"
	 
	foreach cmd of local cmds {
		capture which `cmd'
		if (_rc != 0) {
			ssc install `cmd'
			noi disp in g "{cmd:`cmd'} " in w _col(15) "installed"
		}
	}
	adoupdate `cmds', ssconly
	if ("`r(pkglist)'" != "") adoupdate `r(pkglist)', update ssconly
	global tm_ssccmd = 1  // make sure it does not execute again per session
}



// ---------------------------------------------------------------------------------
//  initial parameters
// ---------------------------------------------------------------------------------

* Directory path
if ("`drive'" == "") {
	if ("`c(hostname)'" == "wbgmsbdat002") local drive "Q"
	else                                   local drive "P"
}

if ("`root'" == "") local root "03.ProjectX\data"

if ("`maindir'" == "") local maindir "`drive':/`root'"


// ----------------------------------------------------------------------------------
// Download GPWG
// ----------------------------------------------------------------------------------

if ("`subcmd'" == "download") {

	tm_dl_gmd, countries(`countries') years(`years') /*
	*/ maindir("`maindir'")  `pause' `clear' `options'
	return add
	exit
}

// ----------------------------------------------------------------------------------
// Load
// ----------------------------------------------------------------------------------

if ("`subcmd'" == "load") {

	noi tm_load, country(`countries') year(`years') type(`type')  /*
	*/ maindir("`maindir'") vermast(`vermast') veralt(`veralt')  /*
		*/ `pause' `clear' `options'
	return add
	exit
}


// ----------------------------------------------------------------------------------
//  create text file (collapsed)
// ----------------------------------------------------------------------------------

if ("`subcmd'" == "create") {

	noi tm_create, countries(`countries') years(`years') type(`type')  /*
	*/ maindir("`maindir'") vermast(`vermast') veralt(`veralt')  /*
		*/ `pause' `clear' `options'
	return add
	exit
}


//========================================================
// Group data
//========================================================

if inlist(lower("`subcmd'"), "group", "groupdata", "gd", "groupd") {
	
	noi tm_groupdata, countries(`countries') years(`years') type(`type')  /*
	*/  vermast(`vermast') veralt(`veralt')  /*
	*/ `pause' `clear' `options'
	return add
	exit
}




} // end of qui

end

// ------------------------------------------------------------------------
// Mata functions
// ------------------------------------------------------------------------


exit

/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Examples:

* download all GMD data
tablemaker download, countries(all) replace



Notes:
1.
2.
3.



Version Control:
