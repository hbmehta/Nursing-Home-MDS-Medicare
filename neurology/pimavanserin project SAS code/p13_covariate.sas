/* ----------------------------------------
Code exported from SAS Enterprise Guide
DATE: Tuesday, November 29, 2022     TIME: 6:43:03 PM
PROJECT: Project pimavanserin
PROJECT PATH: U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp
---------------------------------------- */

/* Unable to determine code to assign library PIMA on sasCCW */
/* Unable to determine code to assign library PIMA on sasCCW */
/* Unable to determine code to assign library PIMA on sasCCW */
/* Unable to determine code to assign library PIMA on sasCCW */
/* Unable to determine code to assign library PIMA on sasCCW */
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

/*   START OF NODE: p13_covariate   */
%LET _CLIENTTASKLABEL='p13_covariate';
%LET _CLIENTPROCESSFLOWNAME='Process Flow';
%LET _CLIENTPROJECTPATH='U:\DUA_055546\_Shared\Project pimavanserin\Project pimavanserin.egp';
%LET _CLIENTPROJECTPATHHOST='VDI-PS-L90350';
%LET _CLIENTPROJECTNAME='Project pimavanserin.egp';
%LET _SASPROGRAMFILE='';
%LET _SASPROGRAMFILEHOST='';

GOPTIONS ACCESSIBLE;
options source;

/*********************************************************************
|	12 - Covariates
|	
|
|
|*********************************************************************/
data pima.index_date;
	set pima.covariate_v09;
	six_mon_prior = intnx('month',index_dt,-6,"sameday");
	format six_mon_prior mmddyy10.;
	keep bene_id index_dt six_mon_prior;
run;

* Step 1. Find the cohort in PDE file;

%macro pde (yr = );
	Data pde_&yr;
		merge &lib.pde&yr._R9984 (keep = bene_id srvc_dt bn gnn days_suply_num prod_srvc_id) pima.covariate_v08(keep=bene_id in=in2);
		by bene_id;
		if in2;
	run;
%mend pde;
%pde (yr = 15);
%pde (yr = 16);
%pde (yr = 17);
%pde (yr = 18);

data pde; set pde_15-pde_18; run;
proc sort data = pde out = pima.pde nodup; by bene_id; run; 

* Step 2 - read in redbook and keep only ndc number, brand and generic name;
data pima.redbook; 			
	set _UPLDS.Redbook2018;
	keep NDCNUM PRODNME GENNME /*THRCLDS THRGRDS*/;
	rename PRODNME = brand GENNME = generic NDCNUM = ndc;
run;
proc sort data=pima.redbook out=pima.redbook; by generic brand; run;

* Step 3 - put medication classes into strings - generate strings of generic names to match to redbook later;
/******************************
  Cholinesterase inhibitor
  Antidepressant
  Antipsychotic (other than pimavanserin)
  Mood stabilizer (incl. lithium)
  Benzodiazepine
  Opioid analgesic
*******************************/
%let ci=%str(donepezil|galantamine|rivastigmine);
%put &ci; *Cholinesterase inhibitor;
%let ad=%str(citalopram|escitalopram|fluoxetine|paroxetine|sertraline|venlafaxine|desvenlafaxine|duloxetine|milnacipran|levomilnacipran|amitriptyline|amoxapine|desipramine|doxepin|imipramine|nortriptyline|protriptyline|trimipramine|isocarboxazid|phenelzine|tranylcypromine|bupropion|mirtazapine|nefazodone|trazodone|vilazodone|vortioxetine);
%put &ad; *Antidepressant;
%let ap=%str(aripiprazole|asenapine|brexpiprazole|cariprazine|clozapine|iloperidone|lurasidone|olanzapine|paliperidone|quetiapine|risperidone|ziprasidone|chlorpromazine|fluphenazine|haloperidol|perphenazine);
%put &ap; *Antipsychotic (other than pimavanserin);
%let ms=%str(lithium|carbamazepine|lamotrigine|valproate|valproic acid|valproate sodium|divalproex sodium);
%put &ms; *Mood stabilizer (incl. lithium);
%let bdz=%str(alprazolam|chlordiazepoxide|clonazepam|clorazepate|diazepam|estazolam|flurazepam|lorazepam|oxazepam|quazepam|temazepam|triazolam);
%put &bdz; *Benzodiazepine;
%let oa=%str(buprenorphine|codeine|fentanyl|transdermal patch|hydrocodone|hydromorphone|meperidine|methadone|morphine|oxycodone|oxymorphone|tapentadol|tramadol);
%put &oa; *Opioid analgesic;


%macro rb (out_file_1, out_file_2, out_file_3, string, med);
	data &out_file_1; 			*;
		if _N_ = 1 then do;
			regEX = prxparse(cats("/(", "&string", ")/i"));
			array pos[2] 3 _temporary_;
		end;

		retain regEX;

		set pima.redbook;
		length gn $50;

		call prxsubstr(regEx, generic, pos[1], pos[2]);

		if pos[1] then gn = substr(generic, pos[1], pos[2]);
		else do;
			call prxsubstr(regEx, brand, pos[1], pos[2]);
		if pos[1] then gn = substr(brand, pos[1], pos[2]);
		end;

		if pos[1] then do;
			gn = lowcase(gn);
			output;
		end;
	run;

	proc sql;							
		create table &out_file_2 as
		select a.ndc, b.*, 1 as &med, (srvc_dt+days_suply_num) as srvc_end_dt format=MMDDYY10. 
		from &out_file_1 as a, pima.pde as b
		where a.ndc = b.prod_srvc_id;
	quit;

	proc sort data = &out_file_2 out = &out_file_2 nodup; by bene_id; run;

	proc sql;							
		create table pima.&out_file_3 as
		select a.bene_id, a.srvc_dt, a.&med, a.srvc_end_dt, b.*
		from &out_file_2 as a, pima.index_date as b
		where a.bene_id = b.bene_id and 
/*			 (a.srvc_dt <= b.index_dt <= a.srvc_end_dt or a.srvc_dt <= (b.index_dt-30) <= a.srvc_end_dt or (b.index_dt-30) <= a.srvc_dt <= b.index_dt);*/
			a.srvc_dt <= b.index_dt <= a.srvc_end_dt;
/*			(a.srvc_dt <= b.index_dt <= a.srvc_end_dt or a.srvc_dt <= (b.index_dt-180) <= a.srvc_end_dt or (b.index_dt-180) <= a.srvc_dt <= b.index_dt);*/
	quit;
	proc sort data = pima.&out_file_3 out = pima.&out_file_3(keep=bene_id index_dt &med) nodupkey; by bene_id index_dt; run;
	
%mend rb;

%rb(ndc_1, ndc_ci, ndc_ci, &ci, ci);
%rb(ndc_2, ndc_ad, ndc_ad, &ad, ad);
%rb(ndc_3, ndc_ap, ndc_ap, &ap, ap);
%rb(ndc_4, ndc_ms, ndc_ms, &ms, ms);
%rb(ndc_5, ndc_bdz, ndc_bdz, &bdz, bdz);
%rb(ndc_6, ndc_oa, ndc_oa, &oa, oa);


data pima.covariate_v10;

	merge pima.covariate_v09(in=in1) pima.ndc_ci; by bene_id index_dt; if in1;

	merge pima.covariate_v09(in=in1) pima.ndc_ad; by bene_id index_dt; if in1;

	merge pima.covariate_v09(in=in1) pima.ndc_ap; by bene_id index_dt; if in1;

	merge pima.covariate_v09(in=in1) pima.ndc_ms; by bene_id index_dt; if in1;

	merge pima.covariate_v09(in=in1) pima.ndc_bdz; by bene_id index_dt; if in1;

	merge pima.covariate_v09(in=in1) pima.ndc_oa; by bene_id index_dt; if in1;

	if ci ne 1 then ci = 0;
	if ad ne 1 then ad = 0;
	if ap ne 1 then ap = 0;
	if ms ne 1 then ms = 0;
	if bdz ne 1 then bdz = 0;
	if oa ne 1 then oa = 0;
run;

proc freq data=pima.covariate_v10;
	table (ci ad ap ms bdz oa)*status/missing norow nopercent;
run;

/******* Anticholinergic burden score ****************************/
%let score_1=%str(alimemazine|theralen|alverine|spasmonal|alprazolam|xanax|aripiprazole|abilify|asenapine|saphris|atenolol|tenormin|bupropion|wellbutrin|zyban|captopril|capoten|cetirizine|zyrtec|chlorthalidone|diuril|hygroton|cimetidine|tagamet|clidinium|librax|clorazepate|tranxene|codeine|contin|colchicine|colcrys|desloratadine|clarinex|diazepam|valium|digoxin|lanoxin|dipyridamole|persantine|disopyramide|norpace|fentanyl|duragesic|actiq|furosemide|lasix|fluvoxamine|luvox|haloperidol|haldol|hydralazine|apresoline|hydrocortisone|cortef|cortaid|iloperidone|fanapt|isosorbide|isordil|ismo|levocetirizine|xyzal|loperamide|immodium|loratadine|claritin|metoprolol|lopressor|toprol|morphine|ms contin|avinza|nifedipine|procardia|adalat|paliperidone|invega|prednisone|deltasone|sterapred|quinidine|quinaglute|ranitidine|zantac|risperidone|risperdal|theophylline|theodur|uniphyl|trazodone|desyrel|triamterene|dyrenium|venlafaxine|effexor|warfarin|coumadin);
%put &score_1; 
%let score_2=%str(amantadine|symmetrel|belladonna|multiple|carbamazepine|tegretol|cyclobenzaprine|flexeril|cyproheptadine|periactin|loxapine|loxitane|meperidine|demerol|methotrimeprazine|levoprome|molindone|moban|nefopam|nefogesic|oxcarbazepine|trileptal|pimozide|orap);
%put &score_2; 
%let score_3=%str(amitriptyline|elavil|amoxapine|asendin|atropine|sal-tropine|benztropine|cogentin|brompheniramine|dimetapp|carbinoxamine|histex|carbihist|chlorpheniramine|chlor-trimeton|chlorpromazine|thorazine|clemastine|tavist|clomipramine|anafranil|clozapine|clozaril|darifenacin|enablex|desipramine|norpramin|dicyclomine|bentyl|dimenhydrinate|dramamine|diphenhydramine|benadryl|doxepin|sinequan|doxylamine|unisom|fesoterodine|toviaz|flavoxate|urispas|hydroxyzine|atarax|vistaril|hyoscyamine|anaspaz|levsin|imipramine|tofranil|meclizine|antivert|methocarbamol|robaxin|nortriptyline|pamelor|olanzapine|zyprexa|orphenadrine|norflex|oxybutynin|ditropan|paroxetine|paxil|perphenazine|trilafon|promethazine|phenergan|propantheline|pro-banthine|propiverine|detrunorm|quetiapine|seroquel|scopolamine|transderm scop|solifenacin|vesicare|thioridazine|mellaril|tolterodine|detrol|trifluoperazine|stelazine|trihexyphenidyl|artane|trimipramine|surmontil|trospium|sanctura);
%put &score_3; 
%macro rb2 (out_file_1, out_file_2, out_file_3, string, med);
	data &out_file_1; 			*;
		if _N_ = 1 then do;
			regEX = prxparse(cats("/(", "&string", ")/i"));
			array pos[2] 3 _temporary_;
		end;

		retain regEX;

		set pima.redbook;
		length gn $50;

		call prxsubstr(regEx, generic, pos[1], pos[2]);

		if pos[1] then gn = substr(generic, pos[1], pos[2]);
		else do;
			call prxsubstr(regEx, brand, pos[1], pos[2]);
		if pos[1] then gn = substr(brand, pos[1], pos[2]);
		end;

		if pos[1] then do;
			gn = lowcase(gn);
			output;
		end;
	run;

	proc sql;							
		create table &out_file_2 as
		select a.ndc, b.*, 1 as &med
		from &out_file_1 as a, pima.pde as b
		where a.ndc = b.prod_srvc_id;
	quit;

	proc sort data = &out_file_2 out = &out_file_2 nodup; by bene_id; run;

	proc sql;							
		create table pima.&out_file_3 as
		select a.bene_id, a.srvc_dt, a.&med, a.ndc, b.*
		from &out_file_2 as a, pima.index_date as b
		where a.bene_id = b.bene_id and b.six_mon_prior < a.srvc_dt < b.index_dt;
	quit;
	proc sort data = pima.&out_file_3 out = pima.&out_file_3(keep=bene_id index_dt ndc &med) nodupkey; by bene_id index_dt ndc; run;
	
%mend rb2;

%rb2(score_1, acb_score_1, acb_score_1, &score_1, acb_score_1);
%rb2(score_2, acb_score_2, acb_score_2, &score_2, acb_score_2);
%rb2(score_3, acb_score_3, acb_score_3, &score_3, acb_score_3);
data pima.acb_score_2;
	set pima.acb_score_2;
	acb_score_2 = 2;
run;
data pima.acb_score_3;
	set pima.acb_score_3;
	acb_score_3 = 3;
run;

proc sql;
	create table acb_score_1_sum as
	select bene_id, index_dt, sum(acb_score_1) as acb_score_1
	from pima.acb_score_1
	group by bene_id, index_dt;
quit;
proc sql;
	create table acb_score_2_sum as
	select bene_id, index_dt, sum(acb_score_2) as acb_score_2
	from pima.acb_score_2
	group by bene_id, index_dt;
quit;
proc sql;
	create table acb_score_3_sum as
	select bene_id, index_dt, sum(acb_score_3) as acb_score_3
	from pima.acb_score_3
	group by bene_id, index_dt;
quit;
data pima.covariate_v11;

	merge pima.covariate_v10(in=in1) acb_score_1_sum; by bene_id index_dt; if in1;

	merge pima.covariate_v10(in=in1) acb_score_2_sum; by bene_id index_dt; if in1;

	merge pima.covariate_v10(in=in1) acb_score_3_sum; by bene_id index_dt; if in1;

	if acb_score_1 = . then acb_score_1 = 0;
	if acb_score_2 = . then acb_score_2 = 0;
	if acb_score_3 = . then acb_score_3 = 0;

	acb_score = acb_score_1+acb_score_2+acb_score_3;
run;

proc freq data=pima.covariate_v10;
	table ap*status;
run;

/*
sex_ident_cd age dualflag e0100ab
				 region	race index_yr abs_g cfs mood
				 acute_mi history_mi chf pvd ADL_cat
				 cvd copd paralysis diabetes diabetes_comp
				 renal_disease any_malignancy solid_tumor mild_liver_disease
				 liver_disease ulcers rheum_disease aids
				 Sch BD Fall Pneumonia UTI
				 ci ad ap ms bdz oa acb_score
*/


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
