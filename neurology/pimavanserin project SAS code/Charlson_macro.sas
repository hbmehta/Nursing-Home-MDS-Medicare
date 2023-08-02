/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:42:51 PM
PROJECT: Project pimavanserin
PROJECT PATH: U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp
---------------------------------------- */

/* ---------------------------------- */
/* MACRO: enterpriseguide             */
/* PURPOSE: define a macro variable   */
/*   that contains the file system    */
/*   path of the WORK library on the  */
/*   server.  Note that different     */
/*   logic is needed depending on the */
/*   server type.                     */
/* ---------------------------------- */
%macro enterpriseguide;
%global sasworklocation;
%local tempdsn unique_dsn path;

%if &sysscp=OS %then %do; /* MVS Server */
	%if %sysfunc(getoption(filesystem))=MVS %then %do;
        /* By default, physical file name will be considered a classic MVS data set. */
	    /* Construct dsn that will be unique for each concurrent session under a particular account: */
		filename egtemp '&egtemp' disp=(new,delete); /* create a temporary data set */
 		%let tempdsn=%sysfunc(pathname(egtemp)); /* get dsn */
		filename egtemp clear; /* get rid of data set - we only wanted its name */
		%let unique_dsn=".EGTEMP.%substr(&tempdsn, 1, 16).PDSE"; 
		filename egtmpdir &unique_dsn
			disp=(new,delete,delete) space=(cyl,(5,5,50))
			dsorg=po dsntype=library recfm=vb
			lrecl=8000 blksize=8004 ;
		options fileext=ignore ;
	%end; 
 	%else %do; 
        /* 
		By default, physical file name will be considered an HFS 
		(hierarchical file system) file. 
		*/
		%if "%sysfunc(getoption(filetempdir))"="" %then %do;
			filename egtmpdir '/tmp';
		%end;
		%else %do;
			filename egtmpdir "%sysfunc(getoption(filetempdir))";
		%end;
	%end; 
	%let path=%sysfunc(pathname(egtmpdir));
    %let sasworklocation=%sysfunc(quote(&path));  
%end; /* MVS Server */
%else %do;
	%let sasworklocation = "%sysfunc(getoption(work))/";
%end;
%if &sysscp=VMS_AXP %then %do; /* Alpha VMS server */
	%let sasworklocation = "%sysfunc(getoption(work))";                         
%end;
%if &sysscp=CMS %then %do; 
	%let path = %sysfunc(getoption(work));                         
	%let sasworklocation = "%substr(&path, %index(&path,%str( )))";
%end;
%mend enterpriseguide;

%enterpriseguide


/* Conditionally delete set of tables or views, if they exists          */
/* If the member does not exist, then no action is performed   */
%macro _eg_conditional_dropds /parmbuff;
	
   	%local num;
   	%local stepneeded;
   	%local stepstarted;
   	%local dsname;
	%local name;

   	%let num=1;
	/* flags to determine whether a PROC SQL step is needed */
	/* or even started yet                                  */
	%let stepneeded=0;
	%let stepstarted=0;
   	%let dsname= %qscan(&syspbuff,&num,',()');
	%do %while(&dsname ne);	
		%let name = %sysfunc(left(&dsname));
		%if %qsysfunc(exist(&name)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;

			%end;
				drop table &name;
		%end;

		%if %sysfunc(exist(&name,view)) %then %do;
			%let stepneeded=1;
			%if (&stepstarted eq 0) %then %do;
				proc sql;
				%let stepstarted=1;
			%end;
				drop view &name;
		%end;
		%let num=%eval(&num+1);
      	%let dsname=%qscan(&syspbuff,&num,',()');
	%end;
	%if &stepstarted %then %do;
		quit;
	%end;
%mend _eg_conditional_dropds;


/* save the current settings of XPIXELS and YPIXELS */
/* so that they can be restored later               */
%macro _sas_pushchartsize(new_xsize, new_ysize);
	%global _savedxpixels _savedypixels;
	options nonotes;
	proc sql noprint;
	select setting into :_savedxpixels
	from sashelp.vgopt
	where optname eq "XPIXELS";
	select setting into :_savedypixels
	from sashelp.vgopt
	where optname eq "YPIXELS";
	quit;
	options notes;
	GOPTIONS XPIXELS=&new_xsize YPIXELS=&new_ysize;
%mend _sas_pushchartsize;

/* restore the previous values for XPIXELS and YPIXELS */
%macro _sas_popchartsize;
	%if %symexist(_savedxpixels) %then %do;
		GOPTIONS XPIXELS=&_savedxpixels YPIXELS=&_savedypixels;
		%symdel _savedxpixels / nowarn;
		%symdel _savedypixels / nowarn;
	%end;
%mend _sas_popchartsize;


ODS PROCTITLE;
OPTIONS DEV=ACTIVEX;
GOPTIONS XPIXELS=0 YPIXELS=0;
FILENAME EGSRX TEMP;
ODS tagsets.sasreport13(ID=EGSRX) FILE=EGSRX
    STYLE=HTMLBlue
    STYLESHEET=(URL="file:///C:/Program%20Files/SASHome/SASEnterpriseGuide/7.1/Styles/HTMLBlue.css")
    NOGTITLE
    NOGFOOTNOTE
    GPATH=&sasworklocation
    ENCODING=UTF8
    options(rolap="on")
;

/*   START OF NODE: Charlson_macro   */
%LET _CLIENTTASKLABEL='Charlson_macro';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/**********************************************************************************************************************/
/*  charlson.comorbidity.macro.sas                                                                                    */
/*  Last updated: 12/5/2018                                                                                           */
/**********************************************************************************************************************/
/*  If you encounter any problems with this macro, please email the SAS log file to seer-medicare@imsweb.com.         */
/**********************************************************************************************************************/
/*  This SAS macro scans ICD-9 diagnosis and procedure codes from hospital and physician claims for sixteen comorbid  */
/*  conditions and creates variables to indicate each condition found and the earliest date in which it was found.    */
/*  It also calculates a comorbidity index (Charlson score) for a patient with respect to cancer.                     */
/*  Note, this version does not look for HCPCS codes.                                                                 */
/*                                                                                                                    */
/*  The macro is designed to look for claims reported in the year prior to diagnosis of cancer, however, the macro    */
/*  can accommodate any time period by inputting different start and end dates for the window of time for which       */
/*  claims are to be scanned for ICD-9 definitions of comorbid conditions. NCI recommends calculating Charlson        */
/*  comorbidity scores using claims for the 12 calendar months prior to the month of diagnosis.                       */
/*                                                                                                                    */
/*  The macro may be run using only hospital claims (MEDPAR) or a combination of hospital and physician claims (NCH   */
/*  and OUTPAT). If physician claims are used, it has a switch in the call statement that may be used so that it can  */
/*  remove codes that are considered to have unreliable diagnosis coding ("ruleouts"). Note, if the RULEOUT Algorithm */
/*  is used, then the input dataset should include claims for at least 30 days before and after the "window".         */
/*                                                                                                                    */
/*  When evaluating codes for reliability, the macro employs the following algorithm:                                 */
/*    KEEPS: all diagnosis codes on MEDPAR claims.                                                                    */
/*    KEEPS: all diagnosis codes on the Outpatient or Physician/Supplier claims that are also found on MEDPAR claims. */
/*    KEEPS: all diagnosis codes on the Outpatient or Physician/supplier claims that appear more than once over a     */
/*     time span exceeding 30 days. (Billing cycles may cause multiple bills to be submitted for the same procedure   */
/*     within that time frame.)                                                                                       */
/*                                                                                                                    */
/*  In order to use this macro:                                                                                       */
/*  1. Include this file in your SAS program                                                                          */
/*      %include '/directory path/charlson.comorbidity.macro.sas';                                                    */
/*  2. Create a clean file of claim records to send to the macro.  You may include information from the claims        */
/*      files MEDPAR, Outpatient SAF and/or Physicial/Supplier (NCH).  All claim records of interest should be        */
/*      "set together" into a single SAS dataset.                                                                     */
/*  3. After setting up your dataset, call the macro COMORB:                                                          */
/*     %macro COMORB(INFILE,PATID,STARTDATE,ENDDATE,CLAIMDATE,CLAIMTYPE,DAYS,DXVARLIST,SXVARLIST,RULEOUT,OUTFILE);    */
/*     For example:                                                                                                   */
/*     %COMORB(Claims,patient_id,start_date,end_date,claim_date,filetype,los,dgn_cd1-dgn_cd25,surg1-surg25,1,Comorb); */
/*     would send the dataset 'Claims', with the person identifier 'patient_id' to the macro.  The number of days     */
/*     for a hospital stay is found in the variable 'los'.  The dataset includes diagnosis codes 'dgn_cd1-dgn_cd25'   */
/*     and surgery codes 'surg1-surg25'.  Diagnosis and surgery codes are in ICD-9 format.  The file source of each   */
/*     claim record is found in the variable 'filetype' (M=MEDPAR, O=Outpatient, N=NCH).  The date of the claim       */
/*     from the claim record is designated as 'claim_date'. The '1' indicates that diagnosis codes will be            */
/*     processed via the RULEOUT algorithm.                                                                           */
/*                                                                                                                    */
/*  The macro returns a SAS dataset (default name=Comorbidities) which contains 1 record for each person that had     */
/*  at least one valid claim record within the specified time window.  The variables included in this data set are    */
/*  the Patient ID,Charlson index, and the comorbid condition indicator flags for the time period of interest.        */
/*  The data set is sorted by the person identifier.                                                                  */
/*                                                                                                                    */
/**********************************************************************************************************************/
/*  INFILE:    Dataset name: a SAS dataset of Medicare claims that contains the following variables:                  */
/*  PATID:     Variable name: Unique ID for each patient.                                                             */
/*  STARTDATE: Variable name: Date the comorbidity window starts, in SAS date format.                                 */
/*  ENDDATE:   Variable name: Date the comorbidity window ends, in SAS date format.                                   */
/*  CLAIMDATE: Variable name: Date of the claim found on the claim file, in SAS date format. This can be created by   */
/*             using the MDY() function (e.g. CLAIMDATE = MDY(FROM_DTM,FROM_DTD,FROM_DTY) or MDY(ADM_M,ADM_D,ADM_Y)). */
/*  CLAIMTYPE: Variable name: the source of the claim record ('M'=MEDPAR, 'O'=OUTPAT, 'N'=NCH). Note, do not use DME. */
/*             For MEDPAR claims, all ICD-9 diagnosis codes are accepted (i.e. none are considered "ruleout" codes).  */
/*  DAYS:      Variable name: contains the length of stay (in days) for hospital visits from MEDPAR.                  */
/*  DXVARLIST: List of variable names: the diagnosis codes in ICD-9 (e.g. DGN_CD1-DGN_CD25). If there are multiple    */
/*             variables, some of which cannot be included in a range, please list them using spaces to separate each */
/*             single element or range (e.g. DGN_CD1-DGN_CD25 ADMDXCDE).                                              */
/*  SXVARLIST: List of variable names: the surgery or procedure codes in ICD-9 (e.g. SRGCDE1-SRGCDE25).  If there are */
/*             multiple variables, some of which cannot be included in a range, please list them using spaces to      */
/*             separate each single element or range (e.g. SRGCDE1-SRGCDE25 PRCDR_CD1).                               */
/*  RULEOUT:   Flag: Set this to 1 (or R), if the "ruleout algorithm" should be invoked (further details below),      */
/*             otherwise set this to 0 (or leave it blank).                                                           */
/*  OUTFILE:   Dataset name: a SAS dataset with the comorbidities and Charlson score determined by the macro.         */
/*             The number of patients in this output file should equal the number patients in the input file.         */
/*             If an output dataset name is not specified, the default name is Comorbidities.                         */
/**********************************************************************************************************************/
/*  RULEOUT Algorithm:                                                                                                */
/*    The ruleout algorithm previously was in a separate macro but now is included within the COMORB macro.           */
/*    It requires a more stringent criteria for which claims to include when identifying comorbidities.               */
/*    Any "stand-alone" outpatient (OUTPAT or NCH) claims that are not confirmed by other claims are considered to be */
/*    "ruleout" diagnoses and are excluded from consideration.  A claim is confirmed if the ICD code on that claim    */
/*    also occurs in MEDPAR or occurs more than 30 days later in OUTPAT or NCH.  All other claims are excluded.       */
/**********************************************************************************************************************/


*** Begin macro COMORB;
%macro COMORB(INFILE,PATID,STARTDATE,ENDDATE,CLAIMDATE,CLAIMTYPE,DAYS,DXVARLIST,SXVARLIST,RULEOUT,OUTFILE);

data claims;
  set &INFILE(keep=&PATID &STARTDATE &ENDDATE &CLAIMDATE &CLAIMTYPE &DAYS &DXVARLIST &SXVARLIST);

/***********************************************************************************************************************/
/*  Example code for creating the "window" of the 1 year before the month of diagnosis                                 */
/*  Create SAS date variables to indicate start and end of window of time in which diagnosis codes will be checked     */
/***********************************************************************************************************************/
/* if not missing(yrdx1) and not missing(modx1) then do;                                                               */
/*   &STARTDATE = mdy(input(modx1,2.),1,(input(yrdx1,4.)-1)); *** One year before the month of diagnosis;              */
/*   &ENDDATE   = mdy(input(modx1,2.),1,input(yrdx1,4.))-1; *** Last day of the month before diagnosis;                */
/*   end;                                                                                                              */
/* format &STARTDATE &ENDDATE mmddyy10.;                                                                               */
/***********************************************************************************************************************/

  *** Select claim records in appropriate window;  
  *** Keep 30 days extra on both sides of the window for the RULEOUT Algorithm;
  *** (for confirming diagnoses in the Outpatient and Physician/Supplier files);
  %IF &RULEOUT = 1 OR &RULEOUT = R %THEN %DO; 
    if (&STARTDATE - 30) <= &CLAIMDATE <= (&ENDDATE + 30);
    %END;
  %ELSE %DO;
    if &STARTDATE <= &CLAIMDATE <= &ENDDATE;
    %END;
  inwindow = (&STARTDATE <= &CLAIMDATE <= &ENDDATE);
run;

*** Separate incoming data into two datasets: surgical procedures and diagnoses;

*** Dataset SXCLAIMS: outputs each surgical procedure code to a separate observation;
*** Only MEDPAR & OUTPAT have procedure codes;
data sxcodes(keep=&PATID &CLAIMDATE sxcode);
  set claims(keep=&PATID &CLAIMDATE &CLAIMTYPE &SXVARLIST inwindow);
  where &CLAIMTYPE in:('M','O') and inwindow;
  array surg (*) $ &SXVARLIST;
  do i=1 to dim(surg);
    if not missing(surg(i)) then do;
      sxcode = upcase(surg(i)); *** Convert any lowercase letters to uppercase;
      output sxcodes;
      end;
    end;
run;

proc sort nodups data=sxcodes;
  by &PATID sxcode &CLAIMDATE;
run;

*** One record per procedure code, with the first and last date it appeared in the window;
data sxcodes(keep=&PATID sxcode first_claim_date last_claim_date daysdiff);
  set sxcodes;
  by &PATID sxcode &CLAIMDATE;
  retain first_claim_date last_claim_date;
  if first.sxcode then first_claim_date = &CLAIMDATE; *** Assign earliest claim date;
  if last.sxcode then do; 
    last_claim_date = &CLAIMDATE; *Assign latest claim date;
    daysdiff = last_claim_date - first_claim_date; 
    output;
    end;
  format first_claim_date last_claim_date mmddyy10.;
run;

*** Dataset DXCLAIMS: outputs each diagnosis code to a separate observation;
data dxcodes(keep=&PATID &CLAIMDATE &CLAIMTYPE &DAYS dxcode inwindow &STARTDATE &ENDDATE);
  set claims(keep=&PATID &CLAIMDATE &CLAIMTYPE &DAYS &DXVARLIST inwindow &STARTDATE &ENDDATE);
  array diag(*) $ &DXVARLIST;
  do i=1 to dim(diag);
    if not missing(diag(i)) then do;
      dxcode = upcase(diag(i)); *** Convert any lowercase letters to uppercase;
      output dxcodes;
      end;
    end;
run;

*** Sort non-missing claims by ID, diagnosis code, and date of claim;
proc sort nodups data=dxcodes;
  by &PATID dxcode &CLAIMDATE;
run;

data dxcodes;
  set dxcodes;
  by &PATID dxcode &CLAIMDATE;
  *** one record per ICD is kept, with first date, first date in window, last date in window, last date;
  retain first_date first_claim_date last_claim_date last_date confirmed dayscheck;
  if first.dxcode then do; 
    first_date = &CLAIMDATE; *** Assign earliest claim date;
    first_claim_date = .; 
    last_claim_date = .; 
    last_date = .; 
    confirmed = 0; 
    dayscheck = 0;
    end;

  if &CLAIMTYPE=:'M' then confirmed = 1;
  if dxcode=:'410' then do; *** for Acute MI only;
    if (&CLAIMTYPE=:'M' and &DAYS>2) then dayscheck = 1; *** the DAYS variable can be character or numeric;
    else if not (&CLAIMTYPE=:'M') then dayscheck = 1; 
    end;

  if inwindow and first_claim_date=. then first_claim_date = &CLAIMDATE;
  if inwindow then last_claim_date = &CLAIMDATE;

  if last.dxcode then do; 
    last_date = &CLAIMDATE; *** Assign latest claim date;
    if first_date>. then daysdiff = last_date - first_date; 
    output;
    end;

  drop &CLAIMDATE inwindow;
  format first_date first_claim_date last_claim_date last_date mmddyy10.;
run;

*** Sort data by patient identifier and restrict claims to comorbidity window;
proc sort data=dxcodes;
  where (&STARTDATE <= first_claim_date <= &ENDDATE);
  by &PATID;
run;

*** Process claims for ruling out certain ICD codes if the RULEOUT indicator flag is set in macro call;
%IF &RULEOUT = 1 OR &RULEOUT = R %THEN %DO;
  proc sort data=dxcodes;
    where confirmed or daysdiff>30; *** delete all unconfirmed ICD codes with first & last date less than 30 days apart;
    by &PATID;
  run;
%END;

*** Some patients can get dropped by the RULEOUT algorithm, so they get added back with this dataset;
proc sort nodupkey data=claims out=cases(keep=&PATID &STARTDATE &ENDDATE);
  where &STARTDATE <= &CLAIMDATE <= &ENDDATE;
  by &PATID;
run;

*** set the default output filename;
%IF %LENGTH(&OUTFILE)=0 %THEN %LET OUTFILE=Comorbidities;

*** Check for comorbidities and create comorbidity indicators and Charlson & NCI Index scores;
*** Setting the CASES dataset last ensures that start & end dates are output for all patients;
data &OUTFILE;
  set sxcodes(in=sx) dxcodes(in=dx) cases(in=c keep=&PATID &STARTDATE &ENDDATE);
  by &PATID;

  length acute_mi history_mi chf pvd cvd copd dementia paralysis diabetes diabetes_comp 
    renal_disease any_malignancy solid_tumor mild_liver_disease liver_disease ulcers rheum_disease aids Charlson 3.;

  length acute_mi_date history_mi_date chf_date pvd_date cvd_date copd_date dementia_date paralysis_date diabetes_date diabetes_comp_date 
         renal_disease_date any_malignancy_date solid_tumor_date mild_liver_disease_date liver_disease_date ulcers_date rheum_disease_date aids_date 8.;

  retain acute_mi--aids acute_mi_date--aids_date;

  *** Initialize comorbidity indicator variables for unique conditions;
  if first.&PATID then call missing(of acute_mi--aids); *** Sets all values to missing;
  if first.&PATID then call missing(of acute_mi_date--aids_date); *** Sets all values to missing;

  *** Scan diagnosis codes for comorbidities and set flag variables when found;
 
  if dx then do; *** Begin diagnosis code loop;

    *** ACUTE MYOCARDIAL INFARCTION;
    if (dxcode in:(/*icd9*/'410', 
				   /*icd10*/'I21', 'I22') and dayscheck) then do; *** los>2;
      acute_mi = 1; 
      if acute_mi_date=. or .<first_claim_date<acute_mi_date then acute_mi_date = first_claim_date; 
      end;

    *** HISTORY OF MYOCARDIAL INFARCTION;
    else if dxcode =   /*icd9*/'412  ' or
			dxcode in:(/*icd10*/'I252') then do; 
      history_mi = 1; 
      if history_mi_date=. or .<first_claim_date<history_mi_date then history_mi_date = first_claim_date; 
      end;

    *** CONGESTIVE HEART FAILURE;
    else if dxcode in:(/*icd9*/'39891','4254','4255','4257','4258','4259','428',
					   /*icd10*/'I43','I50','I099','I110','I130','I132','I255','I420','I425','I426',
                       'I427','I428','I429','P290') then do; 
      chf = 1; 
      if chf_date=. or .<first_claim_date<chf_date then chf_date = first_claim_date; 
      end;

    *** PERIPHERAL VASCULAR DISEASE;
    else if dxcode in:(/*icd9*/'0930','440','441','7854','V434',
					   /*icd10*/'I70','I71','I731','I738','I739','I771','I790','I792','K551','K558',
                         'K559','Z958','Z959') or 
            (/*icd9*/'4420'<=:dxcode<=:'4428') or 
            (/*icd9*/'4431'<=:dxcode<=:'4439') or 
            (/*icd9*/'44770'<=:dxcode<=:'44773') then do; 
      pvd = 1; 
      if pvd_date=. or .<first_claim_date<pvd_date then pvd_date = first_claim_date; 
      end;

    *** CEREBROVASCULAR DISEASE;
    else if dxcode in:(/*icd10*/'G45','G46','I60','I61','I62','I63','I64','I65','I66','I67','I68',
                         'I69','H340') or 
			(/*icd9*/'430'<=:dxcode<=:'438') then do; 
      cvd = 1; 
      if cvd_date=. or .<first_claim_date<cvd_date then cvd_date = first_claim_date; 
      end;

    *** COPD;
    else if dxcode in:(/*icd9*/'4168','4169','5064','5191',
					   /*icd10*/'J40','J41','J42','J43','J44','J45','J46','J47','J60','J61','J62','J63',
                         'J64','J65','J66','J67''I278','I279','J684','J701','J703') or
            (/*icd9*/'490'<=:dxcode<=:'496') or
            (/*icd9*/'500'<=:dxcode<=:'505') then do; 
      copd = 1; 
      if copd_date=. or .<first_claim_date<copd_date then copd_date = first_claim_date; 
      end;

    *** DEMENTIA;
    else if dxcode in:(/*icd9*/'290','2910','2911','2912','29282','2941','3310','3311','3312','33182',
					   /*icd10*/'F00','F01','F02','F03','G30','F051','G311') then do; 
      dementia = 1; 
      if dementia_date=. or .<first_claim_date<dementia_date then dementia_date = first_claim_date; 
      end;

    *** PARALYSIS;
    else if dxcode in:(/*icd9*/'342','3449',
					   /*icd10*/'G81','G82','G041','G114','G801','G802','G830','G831','G832','G833',
                         'G834','G839') or 
			(/*icd9*/'3440'<=:dxcode<=:'3446') then do; 
      paralysis = 1; 
      if paralysis_date=. or .<first_claim_date<paralysis_date then paralysis_date = first_claim_date; 
      end;

    *** DIABETES;
    else if dxcode =   /*icd9*/'250  ' or 
			dxcode in:(/*icd10*/'E100','E101','E106','E108','E109','E110','E111','E116','E118','E119',
                         'E120','E121','E126','E128','E129','E130','E131','E136','E138','E139',
                         'E140','E141','E146','E148','E149') or 
					  (/*icd9*/'2500'<=:dxcode<=:'2503') then do; 
      diabetes = 1; 
      if diabetes_date=. or .<first_claim_date<diabetes_date then diabetes_date = first_claim_date; 
      end;

    *** DIABETES WITH COMPLICATIONS;
    else if dxcode in:(/*icd9*/'3620',
					   /*icd10*/'E102','E103','E104','E105','E107','E112','E113','E114','E115','E117',
                         'E122','E123','E124','E125','E127','E132','E133','E134','E135','E137',
                         'E142','E143','E144','E145','E147') or 
					  (/*icd9*/'2504'<=:dxcode<=:'2509') then do; 
      diabetes_comp = 1; 
      if diabetes_comp_date=. or .<first_claim_date<diabetes_comp_date then diabetes_comp_date = first_claim_date; 
      end;

    *** MODERATE-SEVERE RENAL DISEASE;
    else if dxcode in:(/*icd9*/'40301','40311','40391','40402','40403','40412','40413','40492','40493',
                       '582','583','585','586','588','V420','V451','V56',
					   /*icd10*/'N18','N19','N052','N053','N054','N055','N056','N057','N250','I120',
                         'I131','N032','N033','N034','N035','N036','N037','Z490','Z491','Z492',
                         'Z940','Z992') then do; 
      renal_disease = 1; 
      if renal_disease_date=. or .<first_claim_date<renal_disease_date then renal_disease_date = first_claim_date; 
      end;

	*** Any malignancy, including leukemia and lymphoma;
    else if dxcode in:(/*icd9*/'2386',
					   /*icd10*/'C00','C01','C02','C03','C04','C05','C06','C07','C08','C09','C10','C11',
                         'C12','C13','C14','C15','C16','C17','C18','C19','C20','C21','C22','C23',
                         'C24','C25','C26','C30','C31','C32','C33','C34','C37','C38','C39','C40',
                         'C41','C43','C45','C46','C47','C48','C49','C50','C51','C52','C53','C54',
                         'C55','C56','C57','C58','C60','C61','C62','C63','C64','C65','C66','C67',
                         'C68','C69','C70','C71','C72','C73','C74','C75','C76','C81','C82','C83',
                         'C84','C85','C88','C90','C91','C92','C93','C94','C95','C96','C97') or
			(/*icd9*/'140'<=:dxcode<=:'172') or
			(/*icd9*/'200'<=:dxcode<=:'208') or
			(/*icd9*/'174'<=:dxcode<=:'194') or
			(/*icd9*/'1950'<=:dxcode<=:'1958') then do; 
      any_malignancy = 1;
      if any_malignancy_date=. or .<first_claim_date<any_malignancy_date then any_malignancy_date = first_claim_date; 
      end;
	
	*** Metastatic solid tumor;
    else if dxcode in:(/*icd9*/'196','197','198','199',
					   /*icd10*/'C77','C78','C79','C80') then do; 
      solid_tumor = 1;
      if solid_tumor_date=. or .<first_claim_date<solid_tumor_date then solid_tumor_date = first_claim_date; 
      end;

    *** MILD LIVER DISEASE;
    else if dxcode in:(/*icd9*/'07032','07033','07054','5712','5714','5715','5716',
					   /*icd10*/'B18','K73','K74','K700','K701','K702','K703','K709','K717','K713',
                         'K714','K715','K760','K762','K763','K764','K768','K769','Z944') then do; 
      mild_liver_disease = 1; 
      if mild_liver_disease_date=. or .<first_claim_date<mild_liver_disease_date then mild_liver_disease_date = first_claim_date; 
      end;

    *** MODERATE-SEVERE LIVER DISEASE;
    else if dxcode in:(/*icd9*/'07022','07023','07044','V427',
					   /*icd10*/'K704','K711','K721','K729','K765','K766','K767','I850','I859','I864','I982') or
            (/*icd9*/'4560'<=:dxcode<=:'4562') or
            (/*icd9*/'5722'<=:dxcode<=:'5728') then do; 
      liver_disease = 1; 
      if liver_disease_date=. or .<first_claim_date<liver_disease_date then liver_disease_date = first_claim_date; 
      end;

    *** PEPTIC ULCER DISEASE;
    else if (/*icd9*/'531'<=:dxcode<=:'534') or
			dxcode in:(/*icd10*/'K25','K26','K27','K28') then do; 
      ulcers = 1; 
      if ulcers_date=. or .<first_claim_date<ulcers_date then ulcers_date = first_claim_date; 
      end;

    *** RHEUMATOLOGIC DISEASE;
    else if dxcode in:(/*icd9*/'7100','7101','7104','71481','725  ',
					   /*icd10*/'M05','M32','M33','M34','M06','M315','M351','M353','M360') or 
			('7140'<=:dxcode<=:'7142') then do; 
      rheum_disease = 1; 
      if rheum_disease_date=. or .<first_claim_date<rheum_disease_date then rheum_disease_date = first_claim_date; 
      end;

    *** AIDS;
    else if dxcode in:(/*icd9*/'79571','V08',
					   /*icd10*/'B20','B21','B22','B24') or 
			(/*icd9*/'042'<=:dxcode<=:'044') then do; 
      aids = 1; 
      if aids_date=. or .<first_claim_date<aids_date then aids_date = first_claim_date; 
      end;

    end; *** End diagnosis code loop;


  *** Scan surgery or procedure codes for comorbidities and set flag variables when found;

  if sx then do; *** Begin surgery code loop;

    *** CEREBROVASCULAR DISEASE;
    if sxcode in('0061','0062','0063','0065','3812','3832','3842','3922','3928','3974') then do; 
      cvd = 1; 
      if cvd_date=. or .<first_claim_date<cvd_date then cvd_date = first_claim_date; 
      end;

    *** PERIPHERAL VASCULAR DISEASE;
    else if sxcode in('0060','3813','3814','3815','3816','3818','3833','3834','3836','3838',
                      '3843','3844','3846','3848','3868','3925','3929') then do; 
      pvd = 1; 
      if pvd_date=. or .<first_claim_date<pvd_date then pvd_date = first_claim_date; 
      end;

    *** MODERATE-SEVERE RENAL DISEASE;
    else if sxcode in('3927','3942','3995','5498','5569') then do; 
      renal_disease = 1; 
      if renal_disease_date=. or .<first_claim_date<renal_disease_date then renal_disease_date = first_claim_date; 
      end;

    *** MODERATE-SEVERE LIVER DISEASE;
    else if sxcode in:('391 ','4291','505') then do; 
      liver_disease = 1; 
      if liver_disease_date=. or .<first_claim_date<liver_disease_date then liver_disease_date = first_claim_date; 
      end;

    end; *** End surgery code loop;

  format acute_mi_date--aids_date mmddyy10.;

  *** Define arrays for comorbidity condition flags;
  array comorb (*) acute_mi--aids;
  if last.&PATID then do;
    do i=1 to dim(comorb);
      if comorb(i)=. then comorb(i) = 0;
      end;

    *** Calculate the Charlson Comorbidity Score for prior conditions;
    Charlson = 
      1*(acute_mi or history_mi) +
      1*(chf) +
      1*(pvd) +
      1*(cvd) +
      1*(copd) +
      1*(dementia) +
      2*(paralysis) +
      1*(diabetes and not diabetes_comp) +
      2*(diabetes_comp) +
      2*(renal_disease) +
      1*(mild_liver_disease and not liver_disease) +
      3*(liver_disease) +
      1*(ulcers) +
      1*(rheum_disease) +
      6*(aids)+
	  2*(any_malignancy)+
	  6*(solid_tumor);

    *** Calculate the NCI Comorbidity Index for prior conditions;
    NCIindex = 
      1.14*(acute_mi) +
      1.08*(history_mi) +
      1.91*(chf) +
      1.30*(pvd) +
      1.32*(cvd) +
      1.69*(copd) +
      2.06*(dementia) +
      1.49*(paralysis) +
      1.34*(diabetes or diabetes_comp) +
      1.60*(renal_disease) +
      2.09*(mild_liver_disease or liver_disease) +
      1.08*(ulcers) +
      1.25*(rheum_disease) +
      1.79*(aids);

    output;
  end;

  keep &PATID &STARTDATE &ENDDATE acute_mi--aids acute_mi_date--aids_date Charlson NCIindex;

  label 
    Charlson           = 'Charlson comorbidity score'
    NCIindex           = 'NCI comorbidity index'
    acute_mi           = 'Acute Myocardial Infarction'
    history_mi         = 'History of Myocardial Infarction'
    chf                = 'Congestive Heart Failure'
    pvd                = 'Peripheral Vascular Disease'
    cvd                = 'Cerebrovascular Disease'
    copd               = 'Chronic Obstructive Pulmonary Disease'
    dementia           = 'Dementia'
    paralysis          = 'Hemiplegia or Paraplegia'
    diabetes           = 'Diabetes'
    diabetes_comp      = 'Diabetes with Complications'
    renal_disease      = 'Moderate-Severe Renal Disease'
    mild_liver_disease = 'Mild Liver Disease'
    liver_disease      = 'Moderate-Severe Liver Disease'
    ulcers             = 'Peptic Ulcer Disease'
    rheum_disease      = 'Rheumatologic Disease'
    aids               = 'AIDS'
    acute_mi_date           = 'First indication of Acute Myocardial Infarction'
    history_mi_date         = 'First indication of History of Myocardial Infarction'
    chf_date                = 'First indication of Congestive Heart Failure'
    pvd_date                = 'First indication of Peripheral Vascular Disease'
    cvd_date                = 'First indication of Cerebrovascular Disease'
    copd_date               = 'First indication of Chronic Obstructive Pulmonary Disease'
    dementia_date           = 'First indication of Dementia'
    paralysis_date          = 'First indication of Hemiplegia or Paraplegia'
    diabetes_date           = 'First indication of Diabetes'
    diabetes_comp_date      = 'First indication of Diabetes with Complications'
    renal_disease_date      = 'First indication of Moderate-Severe Renal Disease'
    mild_liver_disease_date = 'First indication of Mild Liver Disease'
    liver_disease_date      = 'First indication of Moderate-Severe Liver Disease'
    ulcers_date             = 'First indication of Peptic Ulcer Disease'
    rheum_disease_date      = 'First indication of Rheumatologic Disease'
    aids_date               = 'First indication of AIDS'
    ;
run;

%mend; *** End macro COMORB;


options nosource;

GOPTIONS NOACCESSIBLE;
%LET _CLIENTTASKLABEL=;
%LET _CLIENTPROCESSFLOWNAME=;
%LET _CLIENTPROJECTPATH=;
%LET _CLIENTPROJECTPATHHOST=;
%LET _CLIENTPROJECTNAME=;
%LET _SASPROGRAMFILE=;
%LET _SASPROGRAMFILEHOST=;

;*';*";*/;quit;run;
ODS _ALL_ CLOSE;
