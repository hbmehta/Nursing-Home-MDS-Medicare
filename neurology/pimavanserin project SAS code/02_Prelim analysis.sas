/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:39:43 PM
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

/*   START OF NODE: 02_Prelim analysis   */
%LET _CLIENTTASKLABEL='02_Prelim analysis';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/**************************************************************************
	Identify G20 pts -- Medpar	
**************************************************************************/
Data g20_m_16;
set &lib.MEDPAR16_R9984 (keep = bene_id dgns_1_cd--dgns_25_cd);
	parkinson = 0;
	array diag dgns_1_cd--dgns_25_cd;
	do i = 1 to dim(diag);
	if substr (diag(i),1,3) in ("G20") then parkinson = 1; 
	end;
run;
Data g20_m_17;
set &lib.MEDPAR17_R9984 (keep = bene_id dgns_1_cd--dgns_25_cd);
	parkinson = 0;
	array diag dgns_1_cd--dgns_25_cd;
	do i = 1 to dim(diag);
	if substr (diag(i),1,3) in ("G20") then parkinson = 1;
	end;
run;
Data g20_m_18;
set &lib.MEDPAR18_R9984 (keep = bene_id dgns_1_cd--dgns_25_cd);
	parkinson = 0;
	array diag dgns_1_cd--dgns_25_cd;
	do i = 1 to dim(diag);
	if substr (diag(i),1,3) in ("G20") then parkinson = 1;
	end;
run;
proc sql;
create table g20_m_pt_16 as 
select bene_id, max (parkinson) as parkinson_diag
from g20_m_16
group by bene_id;
quit;
proc sql;
create table g20_m_pt_17 as 
select bene_id, max (parkinson) as parkinson_diag
from g20_m_17
group by bene_id;
quit;
proc sql;
create table g20_m_pt_18 as 
select bene_id, max (parkinson) as parkinson_diag
from g20_m_18
group by bene_id;
quit;

/**************************************************************************
	Identify G20 pts -- OUTSAF	
**************************************************************************/
Data g20_o_16;
set &lib.OTPTCLMSK16_R9984 (keep = bene_id icd_dgns_cd1--icd_dgns_cd25);
	parkinson = 0;
	array diag icd_dgns_cd1--icd_dgns_cd25;
	do i = 1 to dim(diag);
	if substr (diag(i),1,3) in ("G20") then parkinson = 1; 
	end;
run;
Data g20_o_17;
set &lib.OTPTCLMSK17_R9984 (keep = bene_id icd_dgns_cd1--icd_dgns_cd25);
	parkinson = 0;
	array diag icd_dgns_cd1--icd_dgns_cd25;
	do i = 1 to dim(diag);
	if substr (diag(i),1,3) in ("G20") then parkinson = 1;
	end;
run;
Data g20_o_18;
set &lib.OTPTCLMSK18_R9984 (keep = bene_id icd_dgns_cd1--icd_dgns_cd25);
	parkinson = 0;
	array diag icd_dgns_cd1--icd_dgns_cd25;
	do i = 1 to dim(diag);
	if substr (diag(i),1,3) in ("G20") then parkinson = 1;
	end;
run;
proc sql;
create table g20_o_pt_16 as 
select bene_id, max (parkinson) as parkinson_diag
from g20_o_16
group by bene_id;
quit;
proc sql;
create table g20_o_pt_17 as 
select bene_id, max (parkinson) as parkinson_diag
from g20_o_17
group by bene_id;
quit;
proc sql;
create table g20_o_pt_18 as 
select bene_id, max (parkinson) as parkinson_diag
from g20_o_18
group by bene_id;
quit;

/**************************************************************************
	Identify G20 pts -- CARRIER	
**************************************************************************/
Data g20_c_16;
set &lib.BCARCLMSK16_R9984 (keep = bene_id icd_dgns_cd1-icd_dgns_cd12);
	parkinson = 0;
	array diag icd_dgns_cd1-icd_dgns_cd12;
	do i = 1 to dim(diag);
	if substr (diag(i),1,3) in ("G20") then parkinson = 1; 
	end;
run;
Data g20_c_17;
set &lib.BCARCLMSK17_R9984 (keep = bene_id icd_dgns_cd1-icd_dgns_cd12);
	parkinson = 0;
	array diag icd_dgns_cd1-icd_dgns_cd12;
	do i = 1 to dim(diag);
	if substr (diag(i),1,3) in ("G20") then parkinson = 1;
	end;
run;
Data g20_c_18;
set &lib.BCARCLMSK18_R9984 (keep = bene_id icd_dgns_cd1-icd_dgns_cd12);
	parkinson = 0;
	array diag icd_dgns_cd1-icd_dgns_cd12;
	do i = 1 to dim(diag);
	if substr (diag(i),1,3) in ("G20") then parkinson = 1;
	end;
run;
proc sql;
create table g20_c_pt_16 as 
select bene_id, max (parkinson) as parkinson_diag
from g20_c_16
group by bene_id;
quit;
proc sql;
create table g20_c_pt_17 as 
select bene_id, max (parkinson) as parkinson_diag
from g20_c_17
group by bene_id;
quit;
proc sql;
create table g20_c_pt_18 as 
select bene_id, max (parkinson) as parkinson_diag
from g20_c_18
group by bene_id;
quit;

/**************************************************************************
	Stack all claims	- M, O and C
**************************************************************************/
Data g20_moc_16_clm;
set g20_m_pt_16  g20_o_pt_16  g20_c_pt_16;
run;
proc sql;
create table g20_moc_16_pt as 
select bene_id, max (parkinson_diag) as parkinson_diag_v1
from g20_moc_16_clm
group by bene_id;
quit;

Data g20_moc_17_clm;
set g20_m_pt_17  g20_o_pt_17  g20_c_pt_17;
run;
proc sql;
create table g20_moc_17_pt as 
select bene_id, max (parkinson_diag) as parkinson_diag_v1
from g20_moc_17_clm
group by bene_id;
quit;

Data g20_moc_18_clm;
set g20_m_pt_18  g20_o_pt_18  g20_c_pt_18;
run;
proc sql;
create table g20_moc_18_pt as 
select bene_id, max (parkinson_diag) as parkinson_diag_v1
from g20_moc_18_clm
group by bene_id;
quit;

Data g20_moc_all_clm;
set g20_moc_16_pt  g20_moc_17_pt  g20_moc_18_pt;
run;
proc sql;
create table g20_moc_all_pt as 
select bene_id, max (parkinson_diag_v1) as parkinson_diag_v2
from g20_moc_all_clm
group by bene_id;
quit;

proc freq data =  g20_moc_16_pt;  tables parkinson_diag_v1 / missing; run;
proc freq data =  g20_moc_17_pt;  tables parkinson_diag_v1 / missing; run;
proc freq data =  g20_moc_18_pt;  tables parkinson_diag_v1 / missing; run;
proc freq data =  g20_moc_all_pt; tables parkinson_diag_v2 / missing; run;

/**************************************************************************
	Part D drug data	
**************************************************************************/
Data pima.pima16;
set &lib.PDE16_R9984;
where prod_srvc_id in ("63090010030", "63090017060", "63090034030");
run;

Data pima.pima17;
set &lib.PDE17_R9984;
where prod_srvc_id in ("63090010030", "63090017060", "63090034030");
run;

Data pima.pima18;
set &lib.PDE18_R9984;
where prod_srvc_id in ("63090010030", "63090017060", "63090034030");
run;

proc sql; 
create table pima16_pt as 
select distinct bene_id, 1 as pima_drug 
from pima.pima16;
quit;
proc sql; 
create table pima17_pt as 
select distinct bene_id, 1 as pima_drug 
from pima.pima17;
quit;
proc sql; 
create table pima18_pt as 
select distinct bene_id, 1 as pima_drug 
from pima.pima18;
quit;

Data pima_all_clm;
set pima16_pt  pima17_pt  pima18_pt;
run;
proc sql;
create table pima_all_pt as 
select bene_id, max (pima_drug) as pima_drug_v1
from pima_all_clm
group by bene_id;
quit;

proc freq data =  pima16_pt;  tables pima_drug / missing; run;
proc freq data =  pima17_pt;  tables pima_drug / missing; run;
proc freq data =  pima18_pt;  tables pima_drug / missing; run;
proc freq data =  pima_all_pt; tables pima_drug_v1 / missing; run;

/**************************************************************************
	Merge diagnosis and prescription data - yearly and overall
**************************************************************************/
proc sql;
create table cohort_16 as select * from
g20_moc_16_pt as a left join pima16_pt as b
on a.bene_id = b.bene_id;
quit;
data cohort_16; set cohort_16; if pima_drug = . then pima_drug = 0; run;
proc sql;
create table cohort_17 as select * from
g20_moc_17_pt as a left join pima17_pt as b
on a.bene_id = b.bene_id;
quit;
data cohort_17; set cohort_17; if pima_drug = . then pima_drug = 0; run;
proc sql;
create table cohort_18 as select * from
g20_moc_18_pt as a left join pima18_pt as b
on a.bene_id = b.bene_id;
quit;
data cohort_18; set cohort_18; if pima_drug = . then pima_drug = 0; run;
proc sql;
create table cohort_all as select * from
g20_moc_all_pt as a left join pima_all_pt as b
on a.bene_id = b.bene_id;
quit;
data cohort_all; set cohort_all; if pima_drug_v1 = . then pima_drug_v1 = 0; run;

/**************************************************************************
	Analysis
**************************************************************************/
proc freq data =  cohort_16;  tables parkinson_diag_v1*pima_drug / missing; run;
proc freq data =  cohort_17;  tables parkinson_diag_v1*pima_drug / missing; run;
proc freq data =  cohort_18;  tables parkinson_diag_v1*pima_drug / missing; run;
proc freq data =  cohort_all; tables parkinson_diag_v2*pima_drug_v1 / missing; run;



*******************************************************************;

proc sql;
create table cohort_all as select * from
pima.park_mocd as a left join pima_all_pt as b
on a.bene_id = b.bene_id;
quit;
data cohort_all; set cohort_all; if pima_drug_v1 = . then pima_drug_v1 = 0; run;
proc freq data =  cohort_all; tables parkinson_diag_v2*pima_drug_v1 / missing; run;

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
