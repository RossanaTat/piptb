// ------------------------------------------------------------------------
// MATA code to loop over primus results
// ------------------------------------------------------------------------


mata:

mata set mataoptimize on
mata set matafavor speed
mata set matadebug off // (on when debugging; off in production)
mata set matalnum  off // (on when debugging; off in production)


void tm_ind(string matrix R) {
	i = strtoreal(st_local("i"))
	vars = tokens(st_local("varlist"))
	for (j =1; j<=cols(vars); j++) {
		//printf("j=%s\n", R[i,j])
		st_local(vars[j], R[i,j] )
	} 
} // end of IDs variables

string matrix tm_info(matrix P) {

	survey =  st_local("survey_id")
	status =  st_local("status")
	dlwnote = st_local("dlwnote")


	if (rows(P) == 0) {
		P = survey, status, dlwnote
	}
	else {
		P = P \ (survey, status, dlwnote)
	}
	
	return(P)
}

end

exit

