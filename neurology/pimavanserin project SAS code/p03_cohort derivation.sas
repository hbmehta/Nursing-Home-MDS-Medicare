/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:41:29 PM
PROJECT: Project pimavanserin
PROJECT PATH: U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp
---------------------------------------- */

/* Unable to determine code to assign library PIMA on sasCCW */
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

/*   START OF NODE: p03_cohort derivation   */
%LET _CLIENTTASKLABEL='p03_cohort derivation';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/*********************************************************************
|	Cohort derivation - 03				*	8,661 patients with pimavanserin;
|	First prescription of pimavanserin from May 1, 2016 to Dec 31, 2018
|
|
|*********************************************************************/


/**************************************************************************
	ALL pimavanserin claims
	Pimavanserin has only 3 ndc codes
			"63090010030", "63090017060", "63090034030"
**************************************************************************/

%macro pima_drug (yr = );
	Data pima&yr;
		set &lib.PDE&yr._R9984 (keep=  bene_id srvc_dt gnn days_suply_num prod_srvc_id) ;
		where prod_srvc_id in ("63090010030", "63090017060", "63090034030");
	run;
%mend pima_drug;

%pima_drug (yr = 16);
%pima_drug (yr = 17);
%pima_drug (yr = 18);

Data pima.pima_clm (rename = (srvc_dt = pima_dt));   **All pimavanserin claims;
	set pima16-pima18;
	if "01May2016"d <= srvc_dt <= "31Dec2018"d;
run;

**102871 pimavanserin claims and 9759 unique patients;
proc sql;
select count (bene_id) as all_clms, count (distinct bene_id) as unique_pts
from pima.pima_clm;
quit;

/**************************************************************************
	Create cohort	
**************************************************************************/
proc sql;
	create table cohort_with_pima as
	select * 
	from pima.cohort_v02 as a left join pima.pima_clm as b
	on a.bene_id = b.bene_id
	order by bene_id, park_date, pima_dt;
quit;

Data pima.cohort_v03; 		*620,775 patients;
	set cohort_with_pima;
	by bene_id;
	if first.bene_id;
	if pima_dt = . then pimavanserin = 0; else pimavanserin = 1; 			*9,457 patients with pimavanserin;
	if  pima_dt NE . and  pima_dt < park_date then drug_b4_diag = 1; 
	diff_day = pima_dt - park_date;

	**reassign diagnosis date;
	if pimavanserin = 0 then do;
		park_date_v2 = park_date;
	end;

	if pimavanserin = 1 then do;
		if park_date <= pima_dt then park_date_v2 = park_date;
		if park_date > pima_dt  then park_date_v2 = pima_dt;
	end;

	index_dt = pima_dt;

	format park_date_v2 index_dt mmddyy10.;

run;
/**/
/*proc freq data =  cohort_v02;			**185 patients out of 9457 pimavanserin useras have Rx date before Dx date;*/
/*	tables pimavanserin*drug_b4_diag / missing;*/
/*run;*/
/**/
/*proc means data =  cohort_v02 maxdec= 0;	*/
/*var diff_day;*/
/*where drug_b4_diag = 1; */
/*run;*/
/**/
/*proc sql;*/
/*select count (bene_id) as all_clams, count (distinct bene_id) as unique_pt*/
/*from cohort_v02;*/
/*quit;*/

/**************************************************************************
	Filter for age >= 65 at parkinsnon date    * 223,996 patients
**************************************************************************/
data pima.cohort_v04;
	set pima.cohort_v03;
	age = floor ((intck('month',BENE_BIRTH_DT,park_date_v2) - (day(park_date_v2) < day(BENE_BIRTH_DT))) / 12); 
	if age>=65;
run;
proc freq data =  pima.cohort_v04;		
	tables pimavanserin / missing;
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
