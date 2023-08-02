/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:42:30 PM
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

/*   START OF NODE: p09_covariate   */
%LET _CLIENTTASKLABEL='p09_covariate';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/*********************************************************************
|	08 - Covariates
|	
|
|
|*********************************************************************/

/* Region */
data mbsf15_18_region_o (keep= bene_id state_code);
	set &lib.MBSF_ABCD15_R9984 &lib.MBSF_ABCD16_R9984 &lib.MBSF_ABCD17_R9984 &lib.MBSF_ABCD18_R9984;
run;
proc sort data=mbsf15_18_region_o nodup; by bene_id; run;
data mbsf15_18_region;
	set mbsf15_18_region_o;
	by bene_id;
	if first.bene_id;
run;

data pima.covariate_v01;
	merge pima.cohort_v14(in=in1) mbsf15_18_region;
	by bene_id;
	if in1;
	
	/*Region*/
	IF state_code in ('02','03','05','06','12','13','27','29','32','38','46','50','53') THEN Region = 'West		' ;
	else IF state_code in ('07','20','22','30','31','33','39','47')    THEN Region = 'Northeast		' ; 
	else IF state_code in ('14','15','16','17','23','24','26','28','35','36','43','52') THEN Region = 'Midwest		' ; 
	else IF state_code in ('01','04','08','09','10','11','18','19','21','25','34','37','40','41', 
				'42','44','45','48','49','51') THEN Region = 'South		' ; 
	else if Region not in ('West', 'Northeast', 'Midwest' ,'South')   THEN Region = 'Others		';
	
	
	/*Race*/
	IF RTI_RACE_CD = '1' THEN Race = 'White		';
	else IF RTI_RACE_CD = '2' THEN Race = 'Black	';
	else IF RTI_RACE_CD in ('3', '4', '5','6', '0') THEN Race = 'Other	';
	else Race = 'Missing	';
	drop RTI_RACE_CD;
	
	/*Year of index date*/
	index_yr = year(index_dt);
run;
proc freq data=pima.covariate_v01;
	table region*state_code/missing;
run;

/* Medicaid eligibility */

%macro dual (yr = );
	Data dual_&yr;
		merge &lib.MBSF_ABCD&yr._R9984(keep=bene_id DUAL_STUS_CD_01-DUAL_STUS_CD_12) 
			  pima.covariate_v01(in=in2 keep=bene_id); 
		by bene_id;
		rename DUAL_STUS_CD_01-DUAL_STUS_CD_12 = DUAL_STUS_CD_&yr._01-DUAL_STUS_CD_&yr._12;
		if in2;
	run;

%mend dual;
%dual (yr = 15);
%dual (yr = 16);
%dual (yr = 17);
%dual (yr = 18);
proc sort data=dual_15 out=dual_nodup_15 nodup; by bene_id; run;
proc sort data=dual_16 out=dual_nodup_16 nodup; by bene_id; run;
proc sort data=dual_17 out=dual_nodup_17 nodup; by bene_id; run;
proc sort data=dual_18 out=dual_nodup_18 nodup; by bene_id; run;

/*proc freq data=enroll_nodup_16;*/
/*table hmo_ind_16_01-hmo_ind_16_12 mdcr_entlmt_buyin_ind_16_01;*/
/*run;*/

proc sql;	
	create table dual as 
	select a.*, b.*, c.*, d.*
	from dual_nodup_15 as a , dual_nodup_16 as b, dual_nodup_17 as c , dual_nodup_18 as d
	where a.bene_id = b.bene_id = c.bene_id = d.bene_id 
	order by bene_id;
quit;

data dual_pt;
	merge pima.covariate_v01 dual;
	by bene_id;
run;

data pima.covariate_v02;				
	set dual_pt;

	Diag_index = (year(index_dt)-2015)*12 + month(index_dt);
	start_mon= Diag_index-6;

	*Medicaid eligibility;
	ARRAY dual{48} $ DUAL_STUS_CD_15_01 - DUAL_STUS_CD_15_12
				   	DUAL_STUS_CD_16_01 - DUAL_STUS_CD_16_12
				   	DUAL_STUS_CD_17_01 - DUAL_STUS_CD_17_12
				   	DUAL_STUS_CD_18_01 - DUAL_STUS_CD_18_12;

	Dualflag = 0;
	DO  i = start_mon TO Diag_index;
		IF dual{i} in ('01','02','03','04','05','06', '07','08','09') THEN Dualflag=1; 
	END;

	drop Diag_index start_mon i
		DUAL_STUS_CD_15_01 - DUAL_STUS_CD_15_12
		DUAL_STUS_CD_16_01 - DUAL_STUS_CD_16_12
		DUAL_STUS_CD_17_01 - DUAL_STUS_CD_17_12
		DUAL_STUS_CD_18_01 - DUAL_STUS_CD_18_12;
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
