/*==================================================
project:       Primus Query
Author:        R.Andres Castaneda 
E-email:       acastanedaa@worldbank.org
url:           
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:     9 Aug 2019 - 12:23:48
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/

/*==================================================
              0: Program set up
==================================================*/
program define tm_primus_query, rclass
syntax [anything(name=subcmd id="subcommand")],  ///
[                                   ///
			COUNTries(string)               ///
			Years(numlist)                 ///
			REGions(string)               ///
			maindir(string)               ///
			type(string)                  ///
			survey(string)                ///
			replace                       ///
			vermast(string)               ///
			veralt(string)                ///
			MODule(string)                ///
			clear                         ///
			pause                         ///
] 

version 15

*---------- conditions
if ("`pause'" == "pause") pause on
else                      pause off


/*==================================================
              1: 
==================================================*/

primus query, overalls(approved)

* replace those that finish in GPWG and SARMD or something else. 
replace survey_id = regexs(1)+"GMD" if regexm(survey_id , "(.*)(GPWG.*)$")

generate datetime = string(date_modified, "%tc")

tostring _all, replace force 


*----------1.1: Send to MATA


split survey_id, p("_")

local i = 1
local n = 0
local names survey vermast veralt type

cap confirm var survey_id`i'
while _rc == 0 {

	if inlist(`i', 1, 2, 5, 7) {
		drop survey_id`i'
	}
	else {
		local ++n
		rename survey_id`i' `: word `n' of `names''
	}
	local ++i
	cap confirm var survey_id`i'
}

order country year survey vermast veralt type survey_id datetime

replace veralt  = substr(veralt, 2, .)
replace vermast = substr(vermast, 2, .)

* : list posof "country" in varlist 


/*==================================================
            2: Condition to filter data
==================================================*/

	
	* Countries
	if (lower("`countries'") != "all" ) {
		local countrylist ""
		local countries = upper("`countries'")
		local countrylist: subinstr local countries " " "|", all
		keep if regexm(country, "`countrylist'")
	}
	
	** years
	if ("`years'" != "") {
		numlist "`years'"
		local years  `r(numlist)'
		local yearlist: subinstr local years " " "|", all
		keep if regexm(year, "`yearlist'")
	}

	if ("`vermast'" != "") {
		local vmlist: subinstr local vermast " " "|", all
		keep if regexm(vermast, "`vmlist'")
	}

	if ("`veralt'" != "") {
		local valist: subinstr local veralt " " "|", all
		keep if regexm(veralt, "`valist'")
	}
	
	pause primus_query - before sending to mata


// ------------------------------------------------------------------------
// Send to mata
// ------------------------------------------------------------------------

*----------1.1:
qui ds
local varlist = "`r(varlist)'"

mata: R = st_sdata(.,tokens(st_local("varlist")))

return local varlist = "`varlist'"

end
exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:


