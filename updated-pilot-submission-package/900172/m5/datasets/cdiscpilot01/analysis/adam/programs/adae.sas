*--------------------------------------------------------------
** pch, 1/22/12 -- added amendment 1 coding vars;
**                 re-arranged variable ordering;
*--------------------------------------------------------------;
%include "..\setup.sas";

proc sort data=sdtmnew.AE OUT=AE;
by USUBJID AESEQ;
run;
data AE;
	set AE;
	by USUBJID AESEQ;
	ASTDT=input(strip(AESTDTC),?? yymmdd10.);
	AENDT=input(strip(AEENDTC),?? yymmdd10.);
	if ASTDT>.z and AENDT>.z then ADUR=AENDT-ASTDT+1;
	format ASTDT AENDT DATE9.;
run;

proc sort data=adamnew.ADSL OUT=TEMP(keep=SITEID USUBJID TRT01A TRT01AN AGE AGEGR1 AGEGR1N RACE RACEN SEX SAFFL
TRTSDT TRTEDT RENAME=(TRT01A=TRTA TRT01AN=TRTAN));
by USUBJID;
run;

data AE;
	merge AE(in=inAE) TEMP;
	by USUBJID;
	if inAE;
	if ASTDT=. and length(AESTDTC)=7 /*and input(strip(substr(AESTDTC,1,4)),?? best.)=year(TRTSDT)*/ then do;
		ASTDT=input(compress(AESTDTC||'-01'), yymmdd10.);
		ASTDTF='D';
	end;
	length CQ01NAM $25;
	IF ASTDT>=TRTSDT>.z then ASTDY=ASTDT-TRTSDT+1;
	ELSE IF TRTSDT>ASTDT>.z then ASTDY=ASTDT-TRTSDT;
	IF AENDT>=TRTSDT>.z then AENDY=AENDT-TRTSDT+1;
	ELSE IF TRTSDT>AENDT>.z then AENDY=AENDT-TRTSDT;
	IF ASTDT>.z and TRTSDT>.z then ANLSTDY=ASTDT-TRTSDT+1;
	*IF .z<TRTSDT<=ASTDT<=TRTEDT then ONTRTFL='Y';
	*ELSE ONTRTFL='N';
	IF (ASTDT>=TRTSDT>.z) then TRTEMFL='Y';
	ELSE TRTEMFL='N';
	IF index(aedecod,'APPLICATION') or                                                                                 
    index(aedecod,'DERMATITIS') or                                                                                  
    index(aedecod,'ERYTHEMA') or                                                                                    
    index(aedecod,'BLISTER') or                                                                                     
    (aebodsys='SKIN AND SUBCUTANEOUS TISSUE DISORDERS' and aedecod not in ('COLD SWEAT','HYPERHIDROSIS','ALOPECIA'))
    then  CQ01NAM='DERMATOLOGIC EVENTS';  
run;
/*
proc freq data=AE;
tables TRTEMFL*ATRTEMFL / missing list;
run;
*/
%macro flagfrst(inds=,sortvars=, invar=,outvar=,outds=, ser=, derm=);

proc sort data=&inds out=ds01;
     by usubjid &sortvars ASTDT;
	 where trtemfl='Y'
               %if &invar ne %then and &invar ne '';
               %if &ser ne %then and aeser='Y';
			   %if &derm ne %then and CQ01NAM='DERMATOLOGIC EVENTS';
	 ;
run;

data ds02(keep=usubjid &outvar aeseq);
     set ds01;
         by usubjid &sortvars ASTDT;
	 if %if &invar= %then first.usubjid; %else first.&invar; then do ;
        &outvar='Y';
        output;
	 end;
run;
proc sort data=ds02 out=&outds;
     by usubjid aeseq;
run;
%mend flagfrst;

%* Create first ae flag;

%flagfrst(inds=ae,sortvars=,invar=,outvar=AOCCFL,outds=aea);
%flagfrst(inds=ae,sortvars=aebodsys,invar=aebodsys,outvar=AOCCSFL,outds=aeb);
%flagfrst(inds=ae,sortvars=aebodsys aedecod,invar=aedecod,outvar=AOCCPFL,outds=aec);

*%flagfrst(inds=ae,sortvars=,invar=,outvar=SAEFL,outds=saea, ser=Y);
*%flagfrst(inds=ae,sortvars=aebodsys,invar=aebodsys,outvar=SBODFL,outds=saeb,ser=Y);
*%flagfrst(inds=ae,sortvars=aebodsys aedecod,invar=aedecod,outvar=SDECODFL,outds=saec,ser=Y);
%flagfrst(inds=ae,sortvars=,invar=,outvar=AOCC02FL,outds=saea, ser=Y);
%flagfrst(inds=ae,sortvars=aebodsys,invar=aebodsys,outvar=AOCC03FL,outds=saeb,ser=Y);
%flagfrst(inds=ae,sortvars=aebodsys aedecod,invar=aedecod,outvar=AOCC04FL,outds=saec,ser=Y);
%flagfrst(inds=ae,sortvars=,invar=,outvar=AOCC01FL,outds=derm, ser=,derm=Y);

proc sort data=AE;
by usubjid aeseq;
run;
data AE;
	merge AE AEA AEB AEC SAEA SAEB SAEC DERM;
	by usubjid aeseq;
	label /*AESERN = 'Serious Event (N)'*/
		  /*ONTRTFL = 'On or Off Study Treatment Flag'*/
		  TRTEMFL = 'Treatment Emergent Analysis Flag'
		  AOCCFL = '1st Occurrence of Any AE Flag'
		  AOCCSFL = '1st Occurrence of SOC Flag'
		  AOCCPFL = '1st Occurrence of Preferred Term Flag'
	      /*SAEFL = '1st Serious Occurrence Flag'
		  SBODFL = '1st Serious Ocurrence of SOC Flag'
		  SDECODFL = '1st Serious Ocurrence of Term Flag'*/
		  ASTDT = 'Analysis Start Date'
		  ASTDTF = 'Analysis Start Date Imputation Flag'
		  ASTDY = 'Analysis Start Relative Day'
		  /*ANLSTDY = 'Analysis Start Day'*/
		  AENDT = 'Analysis End Date'
		  AENDY = 'Analysis End Relative Day'
		  TRTA = 'Actual Treatment'
		  TRTAN = 'Actual Treatment (N)'
		  CQ01NAM='Customized Query 01 Name'
		  AOCC02FL='1st Occurrence 02 Flag for Serious'
		  AOCC03FL='1st Occurrence 03 Flag for Serious SOC'
		  AOCC04FL='1st Occurrence 04 Flag for Serious PT'
		  AOCC01FL='1st Occurrence 01 Flag for CQ01'
		  ADUR='AE Duration (days)'
		  ;
run;
data AE;
	retain STUDYID SITEID USUBJID TRTA TRTAN AGE AGEGR1 AGEGR1N RACE RACEN SEX SAFFL TRTSDT TRTEDT 
	ASTDT ASTDTF ASTDY AENDT AENDY ADUR AETERM
AELLT AELLTCD AEDECOD AEPTCD AEHLT AEHLTCD AEHLGT AEHLGTCD AEBODSYS AESOC AESOCCD AESEV AESER AESCAN AESCONG AESDISAB AESDTH AESHOSP AESLIFE AESOD AEREL AEACN
AEOUT AESEQ TRTEMFL AOCCFL AOCCSFL AOCCPFL AOCC02FL AOCC03FL AOCC04FL CQ01NAM AOCC01FL ;
	set AE(keep=STUDYID SITEID USUBJID /*SUBJID*/ TRTAN TRTA AESEQ /*AESPID*/ AETERM AELLT: AEDECOD AEPTCD AEHL: AEBODSYS AESOC: AESEV AESER AEACN AEREL AEOUT AESCAN AESCONG AESDISAB
AESDTH AESHOSP AESLIFE AESOD /*AEDTC AESTDTC AEENDTC AESTDY AEENDY*/   TRTEMFL /*AESERN*/ ASTDT AENDT
ASTDTF CQ01NAM ASTDY AENDY /*ANLSTDY ONTRTFL*/ AOCCFL AOCCSFL AOCCPFL /*SAEFL SBODFL SDECODFL*/ AOCC01FL AOCC02FL AOCC03FL AOCC04FL
AGE AGEGR1 AGEGR1N RACE RACEN SEX SAFFL TRTSDT TRTEDT ADUR);
	by usubjid aeseq;
run;
data adamnew.ADAE(label='Adverse Events Analysis Dataset');
	set AE;
	by USUBJID AESEQ;
	format TRTSDT TRTEDT ASTDT AENDT DATE9.;
run;

endsas;
ods rtf file="C:\Documents and Settings\kam39347\My Documents\CDISC Pilot\SDTM\ADAE.rtf"; 
proc contents data=AE varnum;
run;
ods rtf close;

