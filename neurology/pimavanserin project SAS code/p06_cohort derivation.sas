/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:42:10 PM
PROJECT: Project pimavanserin
PROJECT PATH: U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp
---------------------------------------- */

/* Unable to determine code to assign library PIMA on sasCCW */

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

/*   START OF NODE: p06_cohort derivation   */
%LET _CLIENTTASKLABEL='p06_cohort derivation';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/*/**********************************************************************/
/*|	Cohort derivation - 06*/
/*|	Exclude patients who are in hospital, SNF or hospice on the index date*/
/*|*/
/*|*/
/*|*********************************************************************/*/
/**/
/** 1. exclude patients in SNF/hospital;*/
/*data snf_hos; */
/*	set */
/*	&lib.medpar15_R9984(keep=bene_id admsn_dt dschrg_dt ss_ls_snf_ind_cd los_day_cnt dschrg_dstntn_cd org_npi_num prvdr_num)*/
/*	&lib.medpar16_R9984(keep=bene_id admsn_dt dschrg_dt ss_ls_snf_ind_cd los_day_cnt dschrg_dstntn_cd org_npi_num prvdr_num)*/
/*	&lib.MEDPAR17_R9984(keep=bene_id admsn_dt dschrg_dt ss_ls_snf_ind_cd los_day_cnt dschrg_dstntn_cd org_npi_num prvdr_num)*/
/*	&lib.MEDPAR18_R9984(keep=bene_id admsn_dt dschrg_dt ss_ls_snf_ind_cd los_day_cnt dschrg_dstntn_cd org_npi_num prvdr_num);*/
/*	*/
/*	end_dt = admsn_dt+los_day_cnt;*/
/*	if dschrg_dt ne . then end_dt = dschrg_dt;*/
/*	format end_dt mmddyy10.;*/
/*run;*/
/*proc sort data=snf_hos;*/
/*	by bene_id;*/
/*run;*/
/**/
/**/
/*data pima.cohort_v07;*/
/*	merge snf_hos(keep=bene_id admsn_dt end_dt) pima.cohort_v06(in=in2);*/
/*	by bene_id;*/
/*	if in2;*/
/**/
/*	snf_hos_flag=0;*/
/*	if admsn_dt <= index_dt <= end_dt then snf_hos_flag = 1;*/
/*	if admsn_dt = . or end_dt = . then snf_hos_flag = 1;*/
/*	if snf_hos_flag=0;*/
/*	drop admsn_dt end_dt;*/
/*run;*/
/*proc sort data=pima.cohort_v07 out=pima.cohort_v07 nodup; by bene_id; run;		* 46 350;*/
/**/
/*/** 2. hospice;*/*/
/*/**/*/
/*/*data hospice; */*/
/*/*	set */*/
/*/*	&lib.MDS_ASMT315_R9984(keep=bene_id O0100K1_HOSPC_PRIOR_CD O0100K2_HOSPC_POST_CD A1800_ENTRD_FROM_TXT)*/*/
/*/*	&lib.MDS_ASMT316_R9984(keep=bene_id O0100K1_HOSPC_PRIOR_CD O0100K2_HOSPC_POST_CD A1800_ENTRD_FROM_TXT)*/*/
/*/*	&lib.MDS_ASMT317_R9984(keep=bene_id O0100K1_HOSPC_PRIOR_CD O0100K2_HOSPC_POST_CD A1800_ENTRD_FROM_TXT)*/*/
/*/*	&lib.MDS_ASMT318_R9984(keep=bene_id O0100K1_HOSPC_PRIOR_CD O0100K2_HOSPC_POST_CD A1800_ENTRD_FROM_TXT);*/*/
/*/*run;*/*/
/*/*proc sort data=hospice out=hospice nodup; */*/
/*/*by bene_id; */*/
/*/*run;*/*/
/*/**/*/
/*/*/*proc freq data=hospice;*/*/*/
/*/*/*	table O0100K1_HOSPC_PRIOR_CD O0100K2_HOSPC_POST_CD A1800_ENTRD_FROM_TXT;*/*/*/
/*/*/*run;*/*/*/
/*/**/*/
/*/*data pima.cohort_v07;*/*/
/*/*	merge hospice(keep=bene_id admsn_dt end_dt) pima.cohort_v06(in=in2);*/*/
/*/*	by bene_id;*/*/
/*/*	if in2;*/*/
/*/**/*/
/*/*	if O0100K2_HOSPC_POST_CD='1' then hospice=1;*/*/
/*/*	else hospice=0;*/*/
/*/*	if O0100K1_HOSPC_PRIOR_CD='1' then hosp_prior=1;*/*/
/*/*	else hosp_prior=0;*/*/
/*/*	if A1800_ENTRD_FROM_TXT='07' then hosp_ent=1;*/*/
/*/*	else hosp_ent=0;*/*/
/*/**/*/
/*/*	drop O0100K1_HOSPC_PRIOR_CD O0100K2_HOSPC_POST_CD A1800_ENTRD_FROM_TXT;*/*/
/*/*run;*/*/
/*/*proc sort data=pima.cohort_v07 out=pima.cohort_v07 nodup; */*/
/*/*by bene_id;*/ */
/*/*run;*/*/


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
