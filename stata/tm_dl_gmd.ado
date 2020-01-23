/*==================================================
project:       Download GMD databases
Author:        R.Andres Castaneda 
E-email:       acastanedaa@worldbank.org
url:           
Dependencies:  The World Bank
----------------------------------------------------
Creation Date:    29 Jul 2019 - 16:01:01
Modification Date:   
Do-file version:    01
References:          
Output:             
==================================================*/

/*==================================================
0: Program set up
==================================================*/
program define tm_dl_gmd, rclass
syntax [anything(name=subcmd id="subcommand")],  ///
[                                   ///
COUNtries(string)                   ///
Years(numlist)                      ///
REGions(string)                     ///
maindir(string)                     ///
replace                             ///
clear                              ///
pause                              ///
] 

version 15

*---------- conditions
if ("`pause'" == "pause") pause on
else                      pause off


* ---- Initial parameters
local date = date("`c(current_date)'", "DMY")  // %tdDDmonCCYY  
local time = clock("`c(current_time)'", "hms") // %tcHH:MM:SS  
local date_time = `date'*24*60*60*1000 + `time'  // %tcDDmonCCYY_HH:MM:SS  
local datetimeHRF: disp %tcDDmonCCYY_HH:MM:SS `date_time' 
local datetimeHRF = trim("`datetimeHRF'")	
local user=c(username) 

/*==================================================
1: 
==================================================*/
tm_primus_query, countries(`countries') years(`years') ///
`pause'

local varlist = "`r(varlist)'"
local n = _N

if (`n' == 0) {
	noi disp as error "There is no data in PRIMUS for the convination of " ///
	"country/years selected"
	error
}

/*==================================================
2:  Loop over surveys
==================================================*/
mata: P  = J(0,0, .z)   // matrix with information about each survey
local i = 0
while (`i' < `n') {
	local ++i
	
	cap noi {
		local status     ""
		local dlwnote  ""
		
		
		mata: tm_ind(R)
		
		*--------------------2.2: Load data
		local dwl_execute "datalibweb, country(`country') year(`year') surveyid(`survey') type(GMD) mod(GPWG) vermast(`vermast') veralt(`veralt') clear"
		
		cap `dwl_execute'
		
		if (_rc) {
			local status "dlw error"
			
			local dlwnote "`dwl_execute'"
			
			mata: P = tm_info(P)
			continue
		}
		
		//========================================================
		// Create characteristics
		//========================================================
		
		*------Parameter of the file
		
		if regexm("`r(filename)'", "(.*)(\.dta)$") local filename = regexs(1)
		
		local filename  = regexr("`filename'", "([a-zA-Z]+)$", "PX")
		
		local dirname "`maindir'/`country'/`country'_`year'_`survey'"
		local dirname "`dirname'/`survey_id'/Data"
		
		
		
		
		char _dta[tm_datetimeHRF]    "`datetimeHRF'" 
		char _dta[tm_datetime]       "`date_time'" 
		char _dta[tm_user]           "`user'" 
		char _dta[countrycode]       "`country'"
		char _dta[year]              "`year'"
		char _dta[survey]            "`survey'"
		char _dta[orig_id]           "`survey_id'"
		char _dta[projectX_id]       "`filename'"
		
		
		//========================================================
		// Keep vetted variables
		//========================================================
		
		*----------1.1: clean weight variable
		
		cap confirm var weight, exact 
		if (_rc) {
			cap confirm var weight_p, exact 
			if (_rc == 0) rename weight_p weight
			else {
				cap confirm var weight_h, exact 
				if (_rc == 0) rename weight_h weight
				else {
					noi disp in red "no weight variable found for country(`country') year(`year') veralt(`veralt') "
					continue
				}
			}
		}
		
		
		* make sure no information is lost
		svyset, clear
		recast double welfare
		recast double weight    
		
		* monthly data
		quietly replace welfare=welfare/365
		sort welfare
		
		* drop missing values
		quietly drop if welfare < 0 | welfare == .
		quietly drop if weight <= 0 | weight == .
		
		order weight welfare
		
		//------------ variables in PPP
		
		cap gen double welfare_ppp = welfare/cpi2011/icp2011
		if (_rc) {
			noi disp in red "Error creating welfare_ppp in `survey_id'" _n ///
			"Raw data: {stata `dwl_execute'}"
			continue
		}
		pause after converting to ppp
		
		//------------ vetted variables
		
		local keepvars "welfare welfare_ppp weight subnatid subnatid2 subnatid3 age male urban hsize"
		
		
		local ks ""
		foreach k of local keepvars {
			cap confirm variable `k', exact
			if (_rc) gen `k' = . 
		}
		
		keep `keepvars'
		
		
		//========================================================
		// replace file or save it
		//========================================================
		
		* Confirm file exists
		cap confirm file "`dirname'/`filename'.dta"
		
		if (_rc) {  // if file does not exist
			
			mata: st_local("direxists", strofreal(direxists("`dirname'")))
			
			if (`direxists' != 1) { // if folder does not exist
				cap mkdir "`maindir'/`country'"
				cap mkdir "`maindir'/`country'/`country'_`year'_`survey'"
				cap mkdir "`maindir'/`country'/`country'_`year'_`survey'/`survey_id'"
				cap mkdir "`maindir'/`country'/`country'_`year'_`survey'/`survey_id'/Data"
			}
			
			datasignature set, reset saving("`dirname'/`filename'", replace)
			
			save "`dirname'/`filename'.dta"
			local status "saved"
		}
		
		else {  // If file exists, check data signature
			cap noi datasignature confirm using "`dirname'/`filename'"
			
			if (_rc) { // if data do not match
				if ("`replace'" != "") {
					
					cap mkdir "`dirname'/_vintage"
					preserve   // I cannot use  copy because I nees the tm_datetime char
					
					use "`dirname'/`filename'.dta", clear
					save "`dirname'/_vintage/`filename'_`:char _dta[tm_datetime]'", replace
					
					restore
					
					save "`dirname'/`filename'.dta", replace
					local status "replaced"
					noi disp in y "Data has been replaced"
				}
				
				else { // if replace option not selected
					noi disp in r "Data has not been replaced. Use uption {cmd:replace}"
					local status "not replaced"
				}
			}
			
			else {  // if data is the same
				local status "unchanged"
			}
			
		}  //  end of file exists condition
		
		
		mata: P = tm_info(P)
	} // in case something else fails
	if (_rc) {
		local status "dlw error"
		
		local dlwnote "`dwl_execute'"
		
		mata: P = tm_info(P)
		continue
	}
	
} // end of while 


/*==================================================
3: import results file 
==================================================*/

*----------3.1:
drop _all

getmata (surveyid status dlwnote) = P

* Add chars
char _dta[tm_datetimeHRF]    "`datetimeHRF'" 
char _dta[tm_datetime]       "`date_time'" 
char _dta[tm_user]           "`user'" 


*----------3.2:

cap noi datasignature confirm using "`maindir'/_aux/info/tm_info"
if (_rc) {
	
	datasignature set, reset saving("`maindir'/_aux/info/tm_info", replace)
	saveold "`maindir'/_aux/info/_vintage/tm_info_`date_time'.dta"
	saveold "`maindir'/_aux/info/tm_info.dta", replace
	
}



end


/*====================================================================
Mata functions
====================================================================*/

findfile "tm_functions.mata"
include "`r(fn)'"



exit
/* End of do-file */

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

Notes:
1.
2.
3.


Version Control:



mata
T = ("a", "b")
A = asarray_create()

for (f=1; f<=cols(T); f++) {
	
	asarray(A, T[1,f], st_local(T[1,f]))
	
}


for (loc=asarray_first(A); loc!=NULL; loc=asarray_next(A, loc)) {
  
	asarray_contents(A, loc)
  
}

asarray(A, T[1,f])

end
