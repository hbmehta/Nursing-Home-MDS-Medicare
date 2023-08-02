/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:42:38 PM
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

/*   START OF NODE: p10_covariate   */
%LET _CLIENTTASKLABEL='p10_covariate';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/*********************************************************************
|	09 - Covariates
|	
|
|
|*********************************************************************/

/*variables from mds*/
data pima.mds15_18_var (keep= bene_id trgt_dt 
						C0500_BIMS_SCRE_NUM C0700_SHRT_TERM_MEMRY_CD C0800_LT_MEMRY_CD C0900A_RCALL_CRNT_SEASN_CD C0900B_RCALL_LCTN_ROOM_CD
						C0900C_RCALL_STF_NAME_CD C0900D_RCALL_NH_CD C0900Z_RCALL_NONE_CD C1000_DCSN_MKNG_CD
						D0300_MOOD_SCRE_NUM D0600_STF_MOOD_SCRE_NUM
						G0110A1_BED_MBLTY_SELF_CD G0110B1_TRNSFR_SELF_CD G0110H1_EATG_SELF_CD G0110I1_TOILTG_SELF_CD
						E0100A_HLLCNTN_CD E0100B_DLSN_CD E0100Z_NO_PSYCHOSIS_CD
						E0200A_PHYS_BHVRL_CD E0200B_VRBL_BHVRL_CD E0200C_OTHR_BHVRL_CD E0800_RJCT_EVALTN_CD);
	set &lib.MDS_ASMT315_R9984 &lib.MDS_ASMT316_R9984 &lib.MDS_ASMT317_R9984 &lib.MDS_ASMT318_R9984;
run;
proc sort data=pima.mds15_18_var nodup; by bene_id; run;

proc sql;
	create table mds15_18_var_2 as
	select a.bene_id, a.index_dt, a.status_2, b.*
	from pima.covariate_v02 as a, pima.mds15_18_var as b
	where a.bene_id = b.bene_id and a.index_dt-180 <= b.trgt_dt <= a.index_dt+30;
quit;
proc sort data=mds15_18_var_2 nodup; by bene_id index_dt trgt_dt; run;
proc sql;
	select (count(distinct cats(bene_id,index_dt)))
	from mds15_18_var_2;
quit;
proc sql;
	select (count(distinct cats(bene_id,index_dt)))
	from pima.covariate_v02;
quit;
proc freq data=mds15_18_var_2;
	table C0500_BIMS_SCRE_NUM C0700_SHRT_TERM_MEMRY_CD C0800_LT_MEMRY_CD C0900A_RCALL_CRNT_SEASN_CD C0900B_RCALL_LCTN_ROOM_CD
						C0900C_RCALL_STF_NAME_CD C0900D_RCALL_NH_CD C0900Z_RCALL_NONE_CD C1000_DCSN_MKNG_CD
						D0300_MOOD_SCRE_NUM D0600_STF_MOOD_SCRE_NUM
						G0110A1_BED_MBLTY_SELF_CD G0110B1_TRNSFR_SELF_CD G0110H1_EATG_SELF_CD G0110I1_TOILTG_SELF_CD
						E0100A_HLLCNTN_CD E0100B_DLSN_CD
						E0200A_PHYS_BHVRL_CD E0200B_VRBL_BHVRL_CD E0200C_OTHR_BHVRL_CD E0800_RJCT_EVALTN_CD/missing;
run;

proc freq data=mds15_18_var_2;
	table (E0100A_HLLCNTN_CD E0100B_DLSN_CD)*E0100Z_NO_PSYCHOSIS_CD/missing norow nopercent nocol;
run;
/*Hallucinations or delusions*/
data mds15_18_hll;
	set mds15_18_var_2;
	keep bene_id index_dt trgt_dt E0100A_HLLCNTN_CD E0100B_DLSN_CD e0100ab E0100Z_NO_PSYCHOSIS_CD;
	
	if E0100A_HLLCNTN_CD = "-" then E0100A_HLLCNTN_CD="";
	if E0100B_DLSN_CD = "-" then E0100B_DLSN_CD="";
	
	if E0100A_HLLCNTN_CD ne "" or E0100B_DLSN_CD ne "";

	if E0100A_HLLCNTN_CD='1' or E0100B_DLSN_CD='1' then e0100ab=1; 
	else e0100ab=0;

	by bene_id index_dt;
	if last.bene_id or last.index_dt;
run;

proc sort data=pima.covariate_v02; by bene_id index_dt; run;
data pima.covariate_v03;
	merge pima.covariate_v02(in=in1) mds15_18_hll(keep=bene_id index_dt e0100ab);
	by bene_id index_dt;
	if in1;
run;
proc freq data=pima.covariate_v03;
	table e0100ab/missing;
run;

/*Aggressive behavior*/
data mds15_18_abs;
	set mds15_18_var_2;
	keep bene_id index_dt E0200A_PHYS_BHVRL_CD E0200B_VRBL_BHVRL_CD E0200C_OTHR_BHVRL_CD E0800_RJCT_EVALTN_CD abs abs_g;

	if E0200A_PHYS_BHVRL_CD = "-" then E0200A_PHYS_BHVRL_CD="";
	if E0200B_VRBL_BHVRL_CD = "-" then E0200B_VRBL_BHVRL_CD="";
	if E0200C_OTHR_BHVRL_CD = "-" then E0200C_OTHR_BHVRL_CD="";
	if E0800_RJCT_EVALTN_CD = "-" then E0800_RJCT_EVALTN_CD="";

	if E0200A_PHYS_BHVRL_CD ne "" or E0200B_VRBL_BHVRL_CD ne "" or E0200C_OTHR_BHVRL_CD ne "" or E0800_RJCT_EVALTN_CD ne "";

	if E0200A_PHYS_BHVRL_CD in ('0','1','2','3') and E0200B_VRBL_BHVRL_CD in ('0','1','2','3')
		and E0200C_OTHR_BHVRL_CD in ('0','1','2','3') and E0800_RJCT_EVALTN_CD in ('0','1','2','3')
	then abs=E0200A_PHYS_BHVRL_CD*1+E0200B_VRBL_BHVRL_CD*1+E0200C_OTHR_BHVRL_CD*1+E0800_RJCT_EVALTN_CD*1;

	if abs=0 then abs_g="none			";
	else if 1<=abs<=2 then abs_g="moderate			";
	else if 3<=abs<=12 then abs_g="severe			";

	by bene_id index_dt;
	if last.bene_id or last.index_dt;
run;

data pima.covariate_v04;
	merge pima.covariate_v03(in=in1) mds15_18_abs(keep=bene_id index_dt abs abs_g);
	by bene_id index_dt;
	if in1;
run;
proc freq data=pima.covariate_v04;
	table abs_g/missing;
run;

/*CFS - dementia */
data mds15_18_cfs;
	set mds15_18_var_2;
	keep bene_id index_dt C0500_BIMS_SCRE_NUM C0700_SHRT_TERM_MEMRY_CD C0800_LT_MEMRY_CD 
						C0900A_RCALL_CRNT_SEASN_CD C0900B_RCALL_LCTN_ROOM_CD
						C0900C_RCALL_STF_NAME_CD C0900D_RCALL_NH_CD C0900Z_RCALL_NONE_CD C1000_DCSN_MKNG_CD
						C0900A_D C0900 C0900_V count;

	if C0500_BIMS_SCRE_NUM = "-" then C0500_BIMS_SCRE_NUM="";
	if C0700_SHRT_TERM_MEMRY_CD = "-" then C0700_SHRT_TERM_MEMRY_CD="";
	if C0800_LT_MEMRY_CD = "-" then C0800_LT_MEMRY_CD="";
	if C0900A_RCALL_CRNT_SEASN_CD = "-" then C0900A_RCALL_CRNT_SEASN_CD="";
	if C0900B_RCALL_LCTN_ROOM_CD = "-" then C0900B_RCALL_LCTN_ROOM_CD="";
	if C0900C_RCALL_STF_NAME_CD = "-" then C0900C_RCALL_STF_NAME_CD="";
	if C0900D_RCALL_NH_CD = "-" then C0900D_RCALL_NH_CD="";
	if C0900Z_RCALL_NONE_CD = "-" then C0900Z_RCALL_NONE_CD="";
	if C1000_DCSN_MKNG_CD = "-" then C1000_DCSN_MKNG_CD="";

	if C0500_BIMS_SCRE_NUM ne "" or (C0700_SHRT_TERM_MEMRY_CD ne "" and C0800_LT_MEMRY_CD ne ""
		and C0900A_RCALL_CRNT_SEASN_CD ne "" and C0900B_RCALL_LCTN_ROOM_CD ne "" and C0900C_RCALL_STF_NAME_CD ne ""
		and C0900D_RCALL_NH_CD ne "" and C0900Z_RCALL_NONE_CD ne "" and C1000_DCSN_MKNG_CD ne "");

	/**/
	if C0900A_RCALL_CRNT_SEASN_CD in ("0","1") and C0900B_RCALL_LCTN_ROOM_CD in ("0","1")
		and C0900C_RCALL_STF_NAME_CD in ("0","1") and C0900D_RCALL_NH_CD in ("0","1")
	then C0900A_D=C0900A_RCALL_CRNT_SEASN_CD+C0900B_RCALL_LCTN_ROOM_CD+C0900C_RCALL_STF_NAME_CD+C0900D_RCALL_NH_CD;

	if C0900Z_RCALL_NONE_CD="1" then C0900=0; else C0900=C0900A_D;
	
	C0900_V=4-C0900;

	if C0700_SHRT_TERM_MEMRY_CD in ("0","1") and C0800_LT_MEMRY_CD in ("0","1") and C0900_V ne .
	then count = C0900_V+C0700_SHRT_TERM_MEMRY_CD+C0800_LT_MEMRY_CD+1;

	/**/
	by bene_id index_dt;
	if last.bene_id or last.index_dt;
run;

proc freq data=mds15_18_cfs;table C0500_BIMS_SCRE_NUM;run;
data mds15_18_cfs_2;
	set mds15_18_cfs;

	if C1000_DCSN_MKNG_CD="3" then CPS=5;
	else if C1000_DCSN_MKNG_CD in ("0","1","2") and count = 0 then CPS=0;
	else if C1000_DCSN_MKNG_CD in ("0","1","2") and count in (1,2) then CPS=1;
	else if C1000_DCSN_MKNG_CD in ("0","1","2") and count = 3 then CPS=2;
	else if C1000_DCSN_MKNG_CD in ("0","1","2") and count = 4 then CPS=3;
	else if C1000_DCSN_MKNG_CD in ("0","1","2") and count in (5,6) then CPS=4;

	if CPS=5 then CFS = "Severely imparied			";
	else if CPS in (3,4) or C0500_BIMS_SCRE_NUM in ("00","01","02","03","04","05","06","07")	
		then CFS = "Moderately imparied			";
	else if CPS in (0,1,2) or C0500_BIMS_SCRE_NUM in ("08","09","10","11","12")	
		then CFS = "Mildly imparied			";	
	else if C0500_BIMS_SCRE_NUM in ("13","14","15")	
		then CFS = "Cognitively intact			";
run;

data pima.covariate_v05;
	merge pima.covariate_v04(in=in1) mds15_18_cfs_2(keep=bene_id index_dt CFS);
	by bene_id index_dt;
	if in1;
run;
proc freq data=pima.covariate_v05;
	table CFS/missing;
run;


/*Depression*/
data mds15_18_depr;
	set mds15_18_var_2;
	keep bene_id index_dt trgt_dt D0300_MOOD_SCRE_NUM D0600_STF_MOOD_SCRE_NUM
		D0300_MOOD_SCRE_NUM1 D0600_STF_MOOD_SCRE_NUM1 mood;
	
	if D0300_MOOD_SCRE_NUM = "-" then D0300_MOOD_SCRE_NUM="";
	if D0600_STF_MOOD_SCRE_NUM = "-" then D0600_STF_MOOD_SCRE_NUM="";

	if D0300_MOOD_SCRE_NUM ne "" or D0600_STF_MOOD_SCRE_NUM ne "";
	
   	D0300_MOOD_SCRE_NUM1 = input(D0300_MOOD_SCRE_NUM, 8.);
   	D0600_STF_MOOD_SCRE_NUM1 = input(D0600_STF_MOOD_SCRE_NUM, 8.);

	/**/
	if D0300_MOOD_SCRE_NUM1=0 or D0600_STF_MOOD_SCRE_NUM1=0 
		then mood="No Depression				";
	else if 1<=D0300_MOOD_SCRE_NUM1<=9 or 1<=D0600_STF_MOOD_SCRE_NUM1<=9 
		then mood="Mild Depression					";
	else if 10<=D0300_MOOD_SCRE_NUM1<=27 or 10<=D0600_STF_MOOD_SCRE_NUM1<=30 
		then mood="Moder/Severe Depression				";
	/**/
	by bene_id index_dt;
	if last.bene_id or last.index_dt;
run;

data pima.covariate_v06;
	merge pima.covariate_v05(in=in1) mds15_18_depr(keep=bene_id index_dt mood);
	by bene_id index_dt;
	if in1;
run;
proc freq data=pima.covariate_v06;
	table mood/missing;
run;


/*ADL*/
data mds15_18_adl;
	set mds15_18_var_2;
	keep bene_id index_dt trgt_dt G0110A1_BED_MBLTY_SELF_CD G0110B1_TRNSFR_SELF_CD G0110H1_EATG_SELF_CD 
		G0110I1_TOILTG_SELF_CD bed transfer eat toilet ADL;

	if G0110A1_BED_MBLTY_SELF_CD = "-" then G0110A1_BED_MBLTY_SELF_CD="";
	if G0110B1_TRNSFR_SELF_CD = "-" then G0110B1_TRNSFR_SELF_CD="";
	if G0110H1_EATG_SELF_CD = "-" then G0110H1_EATG_SELF_CD="";
	if G0110I1_TOILTG_SELF_CD = "-" then G0110I1_TOILTG_SELF_CD="";

	if G0110A1_BED_MBLTY_SELF_CD ne "" or G0110B1_TRNSFR_SELF_CD ne "" 
		or  G0110H1_EATG_SELF_CD ne "" or  G0110I1_TOILTG_SELF_CD ne "";

	/**/
	if G0110A1_BED_MBLTY_SELF_CD = "0" then bed=0;
	if G0110A1_BED_MBLTY_SELF_CD = "1" then bed=1;
	if G0110A1_BED_MBLTY_SELF_CD = "2" then bed=2;
	if G0110A1_BED_MBLTY_SELF_CD = "3" then bed=3;
	if G0110A1_BED_MBLTY_SELF_CD in ("4","7","8") then bed=4;
	
	if G0110B1_TRNSFR_SELF_CD = "0" then transfer=0;
	if G0110B1_TRNSFR_SELF_CD = "1" then transfer=1;
	if G0110B1_TRNSFR_SELF_CD = "2" then transfer=2;
	if G0110B1_TRNSFR_SELF_CD = "3" then transfer=3;
	if G0110B1_TRNSFR_SELF_CD in ("4","7","8") then transfer=4;

	if G0110H1_EATG_SELF_CD = "0" then eat=0;
	if G0110H1_EATG_SELF_CD = "1" then eat=1;
	if G0110H1_EATG_SELF_CD = "2" then eat=2;
	if G0110H1_EATG_SELF_CD = "3" then eat=3;
	if G0110H1_EATG_SELF_CD in ("4","7","8") then eat=4;

	if G0110I1_TOILTG_SELF_CD = "0" then toilet=0;
	if G0110I1_TOILTG_SELF_CD = "1" then toilet=1;
	if G0110I1_TOILTG_SELF_CD = "2" then toilet=2;
	if G0110I1_TOILTG_SELF_CD = "3" then toilet=3;
	if G0110I1_TOILTG_SELF_CD in ("4","7","8") then toilet=4;

	ADL = bed+transfer+eat+toilet;
	/**/
	by bene_id index_dt;
	if last.bene_id or last.index_dt;
run;

data pima.covariate_v07;
	merge pima.covariate_v06(in=in1) mds15_18_adl(keep=bene_id index_dt ADL);
	by bene_id index_dt;
	if in1;
run;
proc freq data=pima.covariate_v07;
	table (ADL e0100ab mood CFS abs_g)*status/missing norow nopercent;
run;

data test;
	set pima.covariate_v07;
	if ADL ne .;
	if e0100ab ne .;
	if mood ne "";
	if CFS ne "";
	if abs_g ne "";
run;
proc freq data=test;
	table status ADL e0100ab mood CFS abs_g;
run;




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
