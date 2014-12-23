/*
*@author Sil
*@purpose Controller for  assessment
*
* ****************************************
* Modified by   : Sil
* Modified date : 27-NOV-2013
* Modification  : Added redirection logic based on course Id and CourseDetail page discussed with Mike
* ChangeId      : D001
* ***************************************
* Modified by   : Sil
* Modified date : 17-jan-2014
* Modification  : fixed assessment set bug discussed with Shanker
* ChangeId      : D002
* ***************************************
* //S-213243 [hemant 5/7/2014] - Turn changes under Story S-206998 for all academy from Medacademy
*/
public with sharing class EdgeforceAssessmentController {
    private final static String ASSET_PROGRESS_STATUS_COMPLETE = 'Complete';
    private final static String STUDENT_GRADE = 'Pass';

    public String assessmentIdinParameter{get;set;}
    public Edgeforce_Assessment__c selectedExam{get;set;}        //user selcted Assessment
    public String optionSelectedforCatagoryMatching{get;set;}
    public dateTime timerDatetime{get;set;}
    public double timerValue{get;set;}
    public String showAlert{get;set;}{showAlert = '';}
    public boolean isReadyforSubmit{get;set;}{isReadyforSubmit = false;}
    public String selectedExamId{get;set;}                    //user selected exam on UI
    public String categoryMatchingParaminController{get;set;}
    public List<Edgeforce_Questions__c> listofQuestionsforExamSet {get; set;}      //final list of questions
    public String  examIdinParameter{get;set;}
    public String  userExamid;
    public Edgeforce_Assessment__c examInQAPage{get;set;}
    public Edgeforce_Student_Assessment__c userExaminQAPage{get;set;}
    //public Question_Options__c questionOptions{get;set;}
    public Map<Integer,Edgeforce_Student_Assessment_Questions__c> mapofSequenceandUserExamQuestions{get;set;}
    public Edgeforce_Student_Assessment_Questions__c userExamQuestion{get;set;}
    public Map<String,Integer> mapofQuestionsIdandSequence{get;set;}
    public Map<Integer,processExamQA> mapofprocessQuestionsandAnswers{get;set;}
    public Map<Integer,Edgeforce_Questions__c> mapofSequenceandQuestions{get;set;}
    public List<SelectOption> listofoptionsforUI{get;set;}
    //public List<SelectOption> listofoptionsforReview{get;set;}//todo
    public String optionSelected{get;set;}
    public String[] optionSelectedforMCQ{get;set;}
    public processExamQA QuestionsandAnswers{get;set;}
    public Map<Integer,List<String>> mapofsequenceandSelections{get;set;}
    public Map<string,Edgeforce_Question_Options__c> mapofoptionidandOptions{get;set;}
    public List<Edgeforce_Question_Options__c> listofOptions{get;set;}
    public List<String> listofleftoptionvalues{get;set;}
    public List<SelectOption> listofRightoptionvalues{get;set;}
    public Map<String,Edgeforce_Question_Options__c> mapofoptionIdandcorrectanswer{get;set;}
    public String True_False_Type{get;set;}{True_False_Type = System.label.true_false;}
    public String Single_Choice_Type{get;set;}{Single_Choice_Type = System.label.single_choice;}
    public String Multiple_Choice_Type{get;set;}{Multiple_Choice_Type = System.label.multiple_choice_MC;}
    public String Matching_Type{get;set;}{Matching_Type = System.label.matching;}
    public String Category_Matching_Type{get;set;}{Category_Matching_Type = System.label.category_matching;}
    public Boolean reviewLatercheck{get;set;}{reviewLatercheck = false;}
    public List<Edgeforce_Student_Assessment_Questions__c> listofUserExamQuestionsforReview{get;set;}
    public boolean showReviewPanel{get;set;}{showReviewpanel = false;}
    public String assessmentSetNumber; // set starter set as 1
    public Map<Integer,String> mapofSequenceandMatchingoptionsId{get;set;}
    public String showMcqAlert{get;set;} {showMcqAlert = '';}
    public CategoryMatchingWrapper categoryMatchingWrapper{get;set;}
    public List<CategoryMatchingWrapper> listofCategoryMatchingWrapper{get;set;}
    public List<Selectoption> listofCategoryMatchingSelectOptions{get;set;}
    public Map<String,String> mapofoptionidandcategorySelected{get;set;}
    public Map<String,Set<String>> mapofquestionIdandOptionsSet{get;set;}
    public String reviewsequenceinController{get;set;}
    //input field to store the answer sequence of the matching type question, answer id seperated by "#" and "?" denotes blank
    public String matchingTypeAnswerSequence {get; set;}
    public String previousSelectionforCategoryMatching{get;set;}
    public boolean showUnloadAlert{get;set;}{showUnloadAlert=true;}

     //new addition
    public List<Edgeforce_Training__c> listofTrainings{get;set;}
    public Map<String,Edgeforce_Assessment__c> mapofAssessmentIdandAssessment{get;set;}
    public Map<String,List<String>> mapoftrainingidandListofchildAssessments {get;set;}

    
     // START S-195423 - By Hemlata
    public  Training_User__c trainingUser;
    Map<Id, Course_Progress__c> courseAndCourseProgressMap = new Map<Id, Course_Progress__c>(); 
    public List<Edgeforce_Student_Assessment_Questions__c> listOfWrongAnswers {get;set;} 
    public String missedsequenceinController{get;set;}
    public Boolean isMissed {get;set;} 
    public Map<Integer,Edgeforce_Questions__c> mapofMissedSequenceandQuestions;
    public Boolean PreviousDisabled {get;set;}
    //public  Boolean  isMedicalUser {get  {return IntranetUtility.isMedicalUser();}  set;} //S-213243 [hemant 5/7/2014] - Turn for all academy
    // END S-195423
    
    // Story S-206998 Hemlata
    public Boolean isPreAssessment{get;set;}
    public Integer timeInSec{
        get{
            if(timerValue != null){
                return Integer.valueOf(timerValue)/1000;
            }else{
                return 0;
            }
        }
    }
    //controller
    public EdgeforceAssessmentController(){
        examIdinParameter = '';
        selectedExam = new Edgeforce_Assessment__c();
        listofQuestionsforExamSet = new  List<Edgeforce_Questions__c>();

        listofTrainings = new  List<Edgeforce_Training__c>();
        mapofAssessmentIdandAssessment = new Map<String,Edgeforce_Assessment__c>();
         isPreAssessment = false;


        processTrainingAndAssessments();

         // START S-195423 - By Hemlata
        List<Edgeforce_Student_Assessment_Questions__c> listOfWrongAnswers = new List<Edgeforce_Student_Assessment_Questions__c>();
         isMissed = false;
         Map<Integer,Edgeforce_Questions__c> mapofMissedSequenceandQuestions = new Map<Integer,Edgeforce_Questions__c>();
         PreviousDisabled = false;  
         // END S-195423 - By Hemlata
        //when QA page loads
        if(ApexPages.currentPage().getParameters().get('examId') <> null && ApexPages.currentPage().getParameters().get('examId') <> ''){
            // Story S-206998 START - Hemlata
            if (ApexPages.currentPage().getParameters().get('isPreAssessment') != null && ApexPages.currentPage().getParameters().get('isPreAssessment') != '') {
                    isPreAssessment = Boolean.valueOf(ApexPages.currentPage().getParameters().get('isPreAssessment'));
            }
            system.debug('isPreAssessment**'+isPreAssessment);
            // Story S-206998 END Hemlata
            userExamid = ApexPages.currentPage().getParameters().get('examId');
            userExaminQAPage = new  Edgeforce_Student_Assessment__c();
            examInQAPage = new Edgeforce_Assessment__c();
            //questionOptions = new Question_Options__c();
            mapofSequenceandUserExamQuestions = new  Map<Integer,Edgeforce_Student_Assessment_Questions__c>();
            mapofQuestionsIdandSequence = new  Map<String,Integer>();
            mapofprocessQuestionsandAnswers = new Map<Integer,processExamQA>();
            mapofSequenceandQuestions = new  Map<Integer,Edgeforce_Questions__c>();
            listofoptionsforUI = new List<SelectOption>();
            listofOptions =new List<Edgeforce_Question_Options__c>();
            optionSelectedforMCQ =new String[]{};
                mapofsequenceandSelections = new Map<Integer,List<String>>();
            mapofoptionidandOptions = new  Map<string,Edgeforce_Question_Options__c>();
            listofRightoptionvalues = new List<SelectOption>();
            listofleftoptionvalues = new  List<String>();
            userExamQuestion = new Edgeforce_Student_Assessment_Questions__c();
            mapofoptionIdandcorrectanswer = new Map<String,Edgeforce_Question_Options__c>();
            listofUserExamQuestionsforReview = new List<Edgeforce_Student_Assessment_Questions__c>();
            mapofSequenceandMatchingoptionsId = new Map<Integer,String>();
            listofCategoryMatchingWrapper = new List<CategoryMatchingWrapper>();
            mapofoptionidandcategorySelected = new Map<String,String>();


            //start exam process for user in QA Page
            startExamforUser(userExamid); //we psss assessmentID to this method

        }

    }

    public void processTrainingAndAssessments(){

        for(Edgeforce_Training__c training : [SELECT Id,Name,Description__c, Summary__c FROM Edgeforce_Training__c]){
            if(training <> null){
                listofTrainings.add(training);
            }
        }
           mapoftrainingidandListofchildAssessments = new  Map<String,List<String>>();
          for(Edgeforce_Assessment__c assessment : [Select Total_Required_Questions__c,Training__c,Enforce_Time_Limit__c , Total_Associated_Questions__c, Time_Limit__c, Status__c, Passing_Grade__c, Name, Id
                                   From Edgeforce_Assessment__c
                                   Where  Status__c =:'Active'
                                   order by LastModifiedDate]){
                                       if(assessment <> null && assessment.Training__c <> null){
                                            if(mapoftrainingidandListofchildAssessments.containsKey(assessment.Training__c)){
                                                Set<String> setofAssessmentIdstoStore = new Set<String>();
                                                setofAssessmentIdstoStore.addall(mapoftrainingidandListofchildAssessments.get(assessment.Training__c));
                                                setofAssessmentIdstoStore.add(assessment.Id);
                                                List<String> listofallAssessmentIDs = new List<String>();
                                                listofallAssessmentIDs.addall(setofAssessmentIdstoStore);
                                                mapoftrainingidandListofchildAssessments.put(assessment.Training__c,listofallAssessmentIDs);
                                            }else{
                                              List<String> listofnewAssessmentIDs = new List<String>();
                                              listofnewAssessmentIDs.add(assessment.Id);
                                              mapoftrainingidandListofchildAssessments.put(assessment.Training__c,listofnewAssessmentIDs);
                                            }
                                            mapofAssessmentIdandAssessment.put(assessment.Id,assessment);
                                       }
          }
    }

    //initiate exam process
    public Pagereference  initiateExamProcess(){
       if(Apexpages.currentPage().getParameters().get('assessmentId') <> null && Apexpages.currentPage().getParameters().get('assessmentId') <> ''){
            selectedExamId = Apexpages.currentPage().getParameters().get('assessmentId') ;
        }

        Pagereference initiateAssessmentPage;
        //getting exam detals based on id
        selectedExam  = getExamDetailsbyId(selectedExamId);

        //process questions to be displayed on UI
        listofQuestionsforExamSet = processRandomQuestionsforUser(selectedExam);

        if(listofQuestionsforExamSet <> null && listofQuestionsforExamSet.size()>0){
            //storing tracker
            Edgeforce_Student_Assessment__c userExamTracker = new Edgeforce_Student_Assessment__c();
            userExamTracker.set__c = Integer.valueof(assessmentSetNUmber);
            //userExamTracker.Name = selectedExam.Name+' : '+userinfo.getFirstName()+' : '+system.now();
            userExamTracker.Assessment__c = selectedExam.Id;
            userExamTracker.User__c = userinfo.getUserId();
            if(userExamTracker.User__c <> null)
                userExamTracker.Student__c =  [Select contactid from user where id=:userExamTracker.User__c].contactid;
            userExamTracker.End_Time__c =  System.Now().addMinutes(Integer.valueof(selectedExam.Time_Limit__c)) ;

            try{
                 Database.insert(userExamTracker);
            }catch(Exception e){
                // ApexAuditLog.createLogAndSave('AssessmentController','initiateExamProcess', e.getStackTraceString(), e);
            }

            List<Edgeforce_Student_Assessment_Questions__c> listofUserExamQuestions = new List<Edgeforce_Student_Assessment_Questions__c>();

            if(userExamTracker <> null &&userExamTracker.id <> null){
                //storing all questions to maintain state during exam process

                Integer sequence=1;
                for(Edgeforce_Questions__c examQuesionData:listofQuestionsforExamSet){
                    Edgeforce_Student_Assessment_Questions__c userexamQuestiontoStore = new Edgeforce_Student_Assessment_Questions__c();
                    userexamQuestiontoStore.Sequence__c = sequence;
                    userexamQuestiontoStore.Student_Assessment__c = userExamTracker.Id;
                    userexamQuestiontoStore.student__c = userExamTracker.Student__c;
                    userexamQuestiontoStore.Questions__c = examQuesionData.Id;
                    sequence = sequence+1;
                    listofUserExamQuestions.add(userexamQuestiontoStore);
                }

                try{
                    Database.insert(listofUserExamQuestions);
                }catch(Exception e){
                  // ApexAuditLog.createLogAndSave('AssessmentController','initiateExamProcess', e.getStackTraceString(), e);
                }

            }

            //if there are questions then redirect to exam page and passing examtrackerid in parameter
            if(userExamTracker <> null && listofUserExamQuestions <> null && userExamTracker.Id <> null && listofUserExamQuestions.size()>0){

               examIdinParameter = userExamTracker.Id;
              initiateAssessmentPage = Page.EdgeforceAssessment;
              initiateAssessmentPage.getParameters().put('examId', userExamTracker.Id);

            }else{
                initiateAssessmentPage = null;
            }
        }else{

            initiateAssessmentPage = null;
        }
         initiateAssessmentPage.setRedirect(true);
         return    initiateAssessmentPage;
    }

    //as soon as the QA page load this method start exam process for user
    public void startExamforUser(String currentExamId){
        userExaminQAPage = getUserExamDetails(currentExamId);
        examInQAPage     = getExamDetailsbyId(userExaminQAPage.Assessment__c);
        getUserExamQuestioninQAPage(userExaminQAPage.id);

        timerDatetime = userExaminQAPage.End_Time__c;
        timerValue = timerDatetime != null ? timerDatetime.getTime() - system.now().getTime() : null;
        // system.now().addMinutes(120);

    }


    public Integer totalNoOfQuestion {
        get{
            if(mapofSequenceandQuestions != null){
                return mapofSequenceandQuestions.keySet().size();
            }else{
                return 0;
            }
        }
        set;
    }

    //get Questions in QAPage
    public void getUserExamQuestioninQAPage(String userExamRecordId){
        previousSelectionforCategoryMatching = '';
        //getting user exam details based on id

        for(Edgeforce_Student_Assessment_Questions__c userExamQuestionsData : [Select isCorrectAnswer__c, Student_Assessment__c,CreatedDate, User_Answer__c, Sequence__c, Questions__c, Name, Id ,ReviewLater__c
                                                                     From Edgeforce_Student_Assessment_Questions__c
                                                                     Where Student_Assessment__c=: userExamRecordId order by Sequence__c ]){
                                                                         if(userExamQuestionsData <> null){
                                                                             //preparing map of question id and sequence
                                                                             mapofQuestionsIdandSequence.put(userExamQuestionsData.Questions__c,Integer.valueof(userExamQuestionsData.Sequence__c));
                                                                             //preaparing map of sequence and user exam question
                                                                             mapofSequenceandUserExamQuestions.put(Integer.valueof(userExamQuestionsData.Sequence__c),userExamQuestionsData);
                                                                             previousSelectionforCategoryMatching = userExamQuestionsData.User_Answer__c;

                                                                         }


                                                                     }

        //getting all questions data
        for(Edgeforce_Questions__c localQuestionData : [Select  Title__c, Status__c, Set__c, Question_Type__c, Name, Assessment__c
                                              From Edgeforce_Questions__c
                                              Where id IN : mapofQuestionsIdandSequence.keyset() and Status__c=:'Active']){
                                                  if(localQuestionData <> null){  //Total_Correct_Answer__c
                                                      //preaparing map of sequence and question
                                                      mapofSequenceandQuestions.put(mapofQuestionsIdandSequence.get(localQuestionData.Id),localQuestionData);
                                                  }

                                              }




        //as soon as the page load we will display the first question
        if(mapofSequenceandQuestions.containsKey(1)) {
            getOptionsforQuestions(mapofSequenceandQuestions.get(1).Id);
            QuestionsandAnswers = new processExamQA(1,(mapofSequenceandQuestions.get(1)).Title__c,(mapofSequenceandQuestions.get(1)).Question_Type__c);
            processStateonUI(1);
            system.debug('*****QuestionsandAnswers****'+QuestionsandAnswers);
        }
    }

    public void getOptionsforQuestions(String questionIdValue){

        listofCategoryMatchingSelectOptions = new List<SelectOption>();

        listofoptionsforUI = new List<SelectOption>();
        listofOptions = new List<Edgeforce_Question_Options__c>();
        listofRightoptionvalues = new List<SelectOption>();
        mapofoptionIdandcorrectanswer = new Map<String,Edgeforce_Question_Options__c>();
        Set<SelectOption> setofOptions = new   Set<SelectOption>();
        List<Edgeforce_Question_Options__c>  listofLocalOptions = new  List<Edgeforce_Question_Options__c> ();

        Set<String> setofCategoryValues = new   Set<String>();
        listofCategoryMatchingWrapper = new List<CategoryMatchingWrapper>();
        listofCategoryMatchingSelectOptions.add(new Selectoption('','--'+System.label.select_a_catagory+'--'));
        //List<Question_Options__c> localListofOption = new   List<Question_Options__c>();

        
        // Comment out block below to allow change of data type for questions (option_value__c and right_option_value__c) - Line 416
        for(Edgeforce_Question_Options__c questionOptions : [Select Right_Option_Value__c, Questions__c, Option_Value__c, Name, Id, Correct_Option__c ,Sequence__c
                                                   From Edgeforce_Question_Options__c
                                                   Where  Questions__c =:  questionIdValue order by Sequence__c
                                                  ]){

                                                      if(questionOptions <> null){
                                                          listofLocalOptions.add(questionOptions);
                                                          if(questionOptions.Sequence__c <> null)
                                                              mapofSequenceandMatchingoptionsId.put(Integer.valueof(questionOptions.Sequence__c),questionOptions.id);
                                                          // if(listofCategoryMatchingWrapper.size()==0 )
                                                          //listofCategoryMatchingWrapper.add(new CategoryMatchingWrapper(questionOptions.id,''));
                                                          if(questionOptions.Right_Option_Value__c <> null){
                                                            SelectOption option = new SelectOption(questionOptions.id, questionOptions.Right_Option_Value__c);
                                                            option.setEscapeItem(false);
                                                              listofRightoptionvalues.add(option);
                                                              System.debug('Right option values: ' + listofRightoptionvalues);
                                                              if( questionOptions.Right_Option_Value__c<> null && questionOptions.Right_Option_Value__c<>''){
                                                                  setofCategoryValues.add(questionOptions.Right_Option_Value__c);
                                                              }
                                                          }
                                                          mapofoptionidandOptions.put(questionOptions.Id,questionOptions);
                                                          if(questionOptions.Correct_Option__c <> null && questionOptions.Correct_Option__c == true){
                                                               mapofoptionIdandcorrectanswer.put(questionOptions.Id,questionOptions);
                                                          }



                                                      }


                                                  }

        for(String uniquecategory : setofCategoryValues){
            SelectOption option = new Selectoption(uniquecategory,uniquecategory);
            option.setEscapeItem(false);
            listofCategoryMatchingSelectOptions.add(option);
        }
        //random list item generator
        /*List<Question_Options__c>  listofrandomOptions = new  List<Question_Options__c> ();
List<Sobject> randomOptionssList  = Edgeforce_AssessmentController.processRandumList(listofLocalOptions);
listofrandomOptions =randomOptionssList;*/

    // comment out the block of code to change the data type of option_value__c and right_option_value__c
        for(Edgeforce_Question_Options__c optionobj : listofLocalOptions){

            if(optionobj.Option_Value__c <> null && optionobj.Option_Value__c <> ''){
                SelectOption option = new Selectoption(optionobj.id,optionobj.Option_Value__c);
                option.setEscapeItem(false);
                listofoptionsforUI.add(option);
            }
            listofCategoryMatchingWrapper.add(new CategoryMatchingWrapper(optionobj.id,''));
            listofOptions.add(optionobj);
        }
    }

    //wrapper class for QA process
    public class processExamQA{
        public Integer sequence{get;set;}
        public String QuestionBody{get;set;}
        public String questionType{get;set;}


        public processExamQA(Integer seq,String Question,String questionType){
            this.sequence = seq;
            this.QuestionBody = Question;
            this.questionType = questionType;
        }
    }



    //clicking on next button it will redirect to next questions based on sequence
    public  void getNextQuestion(){
        try{
            showMcqAlert = '';
            showUnloadAlert = false;
            isReadyforSubmit = false;
            // if(mapofSequenceandQuestions.get(QuestionsandAnswers.sequence).Total_Correct_Answer__c <> null && optionSelectedforMCQ.size()<>mapofSequenceandQuestions.get(QuestionsandAnswers.sequence).Total_Correct_Answer__c){
            // showMcqAlert = 'Correct Number of Selection is : '+mapofSequenceandQuestions.get(QuestionsandAnswers.sequence).Total_Correct_Answer__c ;
            // }else{
            storeSelection();
            Integer sequenceNumber  = QuestionsandAnswers.sequence+1;

            if(mapofSequenceandQuestions.containskey(sequenceNumber)){
                //  getUserExamQuestioninQAPage(mapofSequenceandQuestions.get(sequenceNumber).id);
                getOptionsforQuestions(mapofSequenceandQuestions.get(sequenceNumber).Id);
                QuestionsandAnswers = new processExamQA(sequenceNumber,(mapofSequenceandQuestions.get(sequenceNumber)).Title__c,(mapofSequenceandQuestions.get(sequenceNumber)).Question_Type__c);
                processStateonUI(sequenceNumber);
            }

            if(!mapofSequenceandQuestions.containskey(sequenceNumber+1)){
                isReadyforSubmit = true;
            }
            // }
            timerValue = timerDatetime.getTime()-system.now().gettime();
        }catch(Exception e){
            // ApexAuditLog.createLogAndSave('AssessmentController','getNextQuestion', e.getStackTraceString(), e);
        }

    }


     // START S-195423 - By Hemlata
    public  void getMissedNextQuestion(){
        try{
            showMcqAlert = '';
            showUnloadAlert = false;
            isReadyforSubmit = false;
            PreviousDisabled = false;
            // if(mapofSequenceandQuestions.get(QuestionsandAnswers.sequence).Total_Correct_Answer__c <> null && optionSelectedforMCQ.size()<>mapofSequenceandQuestions.get(QuestionsandAnswers.sequence).Total_Correct_Answer__c){
            // showMcqAlert = 'Correct Number of Selection is : '+mapofSequenceandQuestions.get(QuestionsandAnswers.sequence).Total_Correct_Answer__c ;
            // }else{
            storeSelection();
           Integer sequenceNumber  = QuestionsandAnswers.sequence+1;
            
            List<Integer> SequenceNos = new List<Integer>();
            for (Edgeforce_Student_Assessment_Questions__c wrongQuestion: listOfWrongAnswers) {
                SequenceNos.add(Integer.valueof(wrongQuestion.Sequence__c));
            }
            while(sequenceNumber  <= SequenceNos[SequenceNos.size()-1]) {
              if(mapofMissedSequenceandQuestions.containskey(sequenceNumber)){
                //  getUserExamQuestioninQAPage(mapofMissedSequenceandQuestions.get(sequenceNumber).id);
                
                getOptionsforQuestions(mapofMissedSequenceandQuestions.get(sequenceNumber).Id);
                QuestionsandAnswers = new processExamQA(sequenceNumber,(mapofMissedSequenceandQuestions.get(sequenceNumber)).Title__c,(mapofSequenceandQuestions.get(sequenceNumber)).Question_Type__c);
                processStateonUI(sequenceNumber);
                break;
              } else {
                sequenceNumber = sequenceNumber +1;
              }
            }
            SequenceNos.sort();
            if (SequenceNos[SequenceNos.size()-1] == sequenceNumber) {
               isReadyforSubmit = true;
            }
          
            timerValue = timerDatetime.getTime()-system.now().gettime();
        }catch(Exception e){
             //ApexAuditLog.createLogAndSave('AssessmentController','getNextQuestion', e.getStackTraceString(), e);
       }

    }
    
           
    public  void getMissedPreviousQuestion(){
        try{
            showMcqAlert = '';
            showUnloadAlert = false;
            isReadyforSubmit = false;
            PreviousDisabled = false;
            // if(mapofSequenceandQuestions.get(QuestionsandAnswers.sequence).Total_Correct_Answer__c <> null && optionSelectedforMCQ.size()<>mapofSequenceandQuestions.get(QuestionsandAnswers.sequence).Total_Correct_Answer__c){
            // showMcqAlert = 'Correct Number of Selection is : '+mapofSequenceandQuestions.get(QuestionsandAnswers.sequence).Total_Correct_Answer__c ;
            // }else{
            storeSelection();
             List<Integer> SequenceNos = new List<Integer>();
            Integer sequenceNumber  = QuestionsandAnswers.sequence-1;
            //Map<Integer,Edgeforce_Questions__c>  mapofMissedSequenceandQuestions  = getMapofMissedSequenceandQuestions();
            system.debug('mapofMissedSequenceandQuestions**'+mapofMissedSequenceandQuestions);
            system.debug('listOfWrongAnswers**'+listOfWrongAnswers);
            for (Edgeforce_Student_Assessment_Questions__c wrongQuestion: listOfWrongAnswers) {
                SequenceNos.add(Integer.valueof(wrongQuestion.Sequence__c));
            }
             while(sequenceNumber  >= 1) {
              if(mapofMissedSequenceandQuestions.containskey(sequenceNumber)){
                //  getUserExamQuestioninQAPage(mapofMissedSequenceandQuestions.get(sequenceNumber).id);
                 system.debug('sequenceNumber**'+sequenceNumber);
                getOptionsforQuestions(mapofMissedSequenceandQuestions.get(sequenceNumber).Id);
                QuestionsandAnswers = new processExamQA(sequenceNumber,(mapofMissedSequenceandQuestions.get(sequenceNumber)).Title__c,(mapofSequenceandQuestions.get(sequenceNumber)).Question_Type__c);
                processStateonUI(sequenceNumber);
                break;
              } else {
                sequenceNumber = sequenceNumber -1;
              }
            }
             SequenceNos.sort();
            if (SequenceNos[0] == sequenceNumber) {
               PreviousDisabled = true;
            }
            timerValue = timerDatetime.getTime()-system.now().gettime();
        }catch(Exception e){
            // ApexAuditLog.createLogAndSave('AssessmentController','getNextQuestion', e.getStackTraceString(), e);
        }

    }
   // END S-195423 - By Hemlata


    //clicking on previous button it will redirect to previous questions based on sequence
    public  void getPreviousQuestion(){

        try{
            showMcqAlert = '';
            isReadyforSubmit = false;
            // if(mapofSequenceandQuestions.get(QuestionsandAnswers.sequence).Total_Correct_Answer__c <> null && optionSelectedforMCQ.size()<>mapofSequenceandQuestions.get(QuestionsandAnswers.sequence).Total_Correct_Answer__c){
            // showMcqAlert = 'Correct Number of Selection is : '+mapofSequenceandQuestions.get(QuestionsandAnswers.sequence).Total_Correct_Answer__c ;
            // }else{
            storeSelection();
            Integer sequenceNumber  = QuestionsandAnswers.sequence-1;

            if(mapofSequenceandQuestions.containskey(sequenceNumber)){
                // getUserExamQuestioninQAPage(mapofSequenceandQuestions.get(sequenceNumber).id);
                getOptionsforQuestions(mapofSequenceandQuestions.get(sequenceNumber).Id);
                QuestionsandAnswers = new processExamQA(sequenceNumber,(mapofSequenceandQuestions.get(sequenceNumber)).Title__c,(mapofSequenceandQuestions.get(sequenceNumber)).Question_Type__c);
                processStateonUI(sequenceNumber);
            }
            //}
            timerValue = timerDatetime.getTime()-system.now().gettime();
        } catch(Exception e){
             //ApexAuditLog.createLogAndSave('AssessmentController','getPreviousQuestion', e.getStackTraceString(), e);
        }

    }

    //maintain state on UI
    public void processStateonUI(Integer sequenceNumberofQuestion){
        //timerValue = timerDatetime.getTime()-system.now().gettime();
        if(mapofSequenceandUserExamQuestions.containskey(sequenceNumberofQuestion)){
            if(QuestionsandAnswers.questionType == True_False_Type|| QuestionsandAnswers.questionType == Single_Choice_Type || QuestionsandAnswers.questionType == Multiple_Choice_Type){
                system.debug('*******mapofSequenceandUserExamQuestions***********'+mapofSequenceandUserExamQuestions.get(sequenceNumberofQuestion));

                List<String> listofSElectedOptionsfromdatabase = new List<String>();
                String userAnswer = (mapofSequenceandUserExamQuestions.get(sequenceNumberofQuestion)).User_answer__c;
                if(userAnswer <>null &&userAnswer <>''){
                    listofSElectedOptionsfromdatabase.addall(userAnswer.split('#'));
                }
                if(listofSElectedOptionsfromdatabase <> null && listofSElectedOptionsfromdatabase.size()>0){
                    if(QuestionsandAnswers.questionType == True_False_Type|| QuestionsandAnswers.questionType == Single_Choice_Type) {
                        optionSelected = listofSElectedOptionsfromdatabase[0];
                    }else if(QuestionsandAnswers.questionType == Multiple_Choice_Type){

                        optionSelectedforMCQ = listofSElectedOptionsfromdatabase;

                    }
                }
            }else{


                String userAnswerinCategorymatching = (mapofSequenceandUserExamQuestions.get(sequenceNumberofQuestion)).User_answer__c;
                categoryMatchingParaminController = userAnswerinCategorymatching;
                Map<String,String> mapofoptionIdandselected=new Map<String,String>();
                system.debug('****in****'+userAnswerinCategorymatching);
                Set<String> optionsetIds = new  Set<String>();
                listofCategoryMatchingWrapper = new List<CategoryMatchingWrapper>();
                if(userAnswerinCategorymatching <> null && userAnswerinCategorymatching<>''){
                    for(String fullAnswer :userAnswerinCategorymatching.split(';')){
                    System.debug('******first 18*****'+fullAnswer.substring(0,18));
                    System.debug('******first 18*****'+fullAnswer.substring(19,fullAnswer.length()));
                        mapofoptionIdandselected.put(fullAnswer.substring(0,18),fullAnswer.substring(19,fullAnswer.length()));
                    }
                }
                system.debug('****mapofoptionIdandselected****'+mapofoptionIdandselected);
                for(Edgeforce_Question_Options__c option : listofOptions){
                    if(mapofoptionIdandselected.containsKey(option.id)){
                        listofCategoryMatchingWrapper.add(new CategoryMatchingWrapper(option.id,mapofoptionIdandselected.get(option.id)));
                    }else{
                        listofCategoryMatchingWrapper.add(new CategoryMatchingWrapper(option.id,'None'));
                    }

                }
                system.debug('****listofCategoryMatchingWrapper****'+listofCategoryMatchingWrapper);
            }




            userExamQuestion = [Select Sequence__c,User_Answer__c,ReviewLater__c
                                From Edgeforce_Student_Assessment_Questions__c
                                Where id=:mapofSequenceandUserExamQuestions.get(sequenceNumberofQuestion).id];
            if(QuestionsandAnswers.questionType == Matching_Type){
                matchingTypeAnswerSequence = userExamQuestion.User_Answer__c;
                if(String.isBlank(matchingTypeAnswerSequence)){
                    matchingTypeAnswerSequence = fetchRandomAnswerForMatchingType(listofOptions);
                }
                quewrapper=new List<wrapquestion>();
                List<String> part1=matchingTypeAnswerSequence.split(',');
                String[] part2;
                String[] part3;
                String queid = '';
                String ansid = '';
                String answered = '';
                for(String s:part1){
                    part2 = new String[]{} ;
                        part2=s.split('#');
                    if(part2 <> null && part2.size()>0){
                        queid=part2[0];
                        if(part2.size()>1){
                            part3 = new String[]{};
                                part3=part2[1].split('@');
                            if(part3 <> null && part3.size()>0)
                                ansid=part3[0];
                            if(part3.size()>1){
                                answered=part3[1];
                            }
                        }
                    }


                    quewrapper.add(new wrapquestion(mapofoptionidandOptions, queid, ansid, answered));
                }


                matchingAnswerJSONString=JSON.serialize(new wrapwithtitle('question',quewrapper));

            }
            system.debug('*****userExamQuestion*****'+userExamQuestion.User_Answer__c);



            //if(QuestionsandAnswers.questionType == Category_Matching_Type)

        }


    }



    /**
    *@author Manish
    *@purpose get a random answer string for Matching type question using list of options
    */
    private String fetchRandomAnswerForMatchingType(List<Edgeforce_Question_Options__c> optionsList){

        String resultString = '';
        List<Edgeforce_Question_Options__c> rightList = (List<Edgeforce_Question_Options__c>)EdgeforceAssessmentController.processRandumList(optionsList);

        for(Integer i=0; i < optionsList.size(); i++){
            for(Integer j=0; j < rightList.size(); j++){
                if(i == j){
                    if(resultString != ''){
                        resultString += ',';
                    }
                    resultString += optionsList[i].Id+'#'+rightList[j].Id+'@n';
                }
            }
        }

        return resultString;
    }


    /* LOGIC FOR MATCHING TYPE STARTS */

    public String matchingAnswerJSONString{get;set;}
    List<wrapquestion> quewrapper;

    public class wrapquestion{
        public String queid{get;set;}
        public String ansid{get;set;}
        public String que{get;set;}
        public String ans{get;set;}
        public String answered{get;set;}
        public wrapquestion( Map<String, Edgeforce_Question_Options__c> mapofoptionidandOptions,String queid,String ansid,String answered){
            this.queid=queid;
            this.ansid=ansid;
            System.debug('******mapofoptionidandOptions******'+mapofoptionidandOptions);
            System.debug('**********queid + ansid*****'+queid+'  '+'ansid');
            // comment out the lines below to change data type of option_value and right_option_value__c
            this.que=mapofoptionidandOptions.get(queid).Option_Value__c;
            this.ans=mapofoptionidandOptions.get(ansid).Right_Option_Value__c;
            this.answered=answered;
        }
    }

    public class wrapwithtitle{
        String quetitle{get;set;}
        List<wrapquestion> wrappedquestionlist{get;set;}

        public wrapwithtitle(String quetitle,List<wrapquestion> wrappedquestionlist){
            this.quetitle=quetitle;
            this.wrappedquestionlist=wrappedquestionlist;
        }
    }


    /* LOGIC FOR MATCHING TYPE ENDS */


    //store data which has single selection value like true/false ,
    public void storeSelection(){

        reviewLatercheck = userExamQuestion.Reviewlater__c;
        userExamQuestion =  mapofSequenceandUserExamQuestions.get(QuestionsandAnswers.sequence);
        userExamQuestion.Reviewlater__c = reviewLatercheck;
        List<String> listofselectedoptions = new  List<String>();

        if((QuestionsandAnswers.questionType == True_False_Type) || (QuestionsandAnswers.questionType == Single_Choice_Type)) {
            if(optionSelected <> null && optionSelected <> ''){
                listofselectedoptions.add(optionSelected);
                mapofsequenceandSelections.put(QuestionsandAnswers.sequence,listofselectedoptions);
                userExamQuestion.User_Answer__c = mapofoptionidandOptions.get(optionSelected).id;

            }
        }else if(QuestionsandAnswers.questionType == Multiple_Choice_Type){

            String valueToUpdate = '';
            if(optionSelectedforMCQ <> null && optionSelectedforMCQ.size()>0){
                listofselectedoptions.addall(optionSelectedforMCQ);
                mapofsequenceandSelections.put(QuestionsandAnswers.sequence,listofselectedoptions);

                for(String selectedMCQ : optionSelectedforMCQ){
                    if(valueToUpdate <> ''){
                        valueToUpdate  =valueToUpdate +'#'+ mapofoptionidandOptions.get(selectedMCQ).id ;
                    }else{
                        valueToUpdate=  mapofoptionidandOptions.get(selectedMCQ).id ;
                    }
                }
                userExamQuestion.User_Answer__c  = valueToUpdate;
            } else{
                userExamQuestion.User_Answer__c  = valueToUpdate;
            }
        }




        if(QuestionsandAnswers.questionType == True_False_Type || QuestionsandAnswers.questionType== Single_Choice_Type||QuestionsandAnswers.questionType==Multiple_Choice_Type){
            if(listofselectedoptions <> null && listofselectedoptions.size()>0 && mapofoptionIdandcorrectanswer.keyset().size() == listofselectedoptions.size()) {
                Set<String> setofWrongOptions = new Set<String>();
                Set<String> setofCorrectAnswerOptions = new   Set<String>();
                for(String optionIdValue : listofselectedoptions) {
                    if(mapofoptionIdandcorrectanswer.containsKey(optionIdValue)){
                        setofCorrectAnswerOptions.add(optionIdValue);
                    }else{
                        setofWrongOptions.add(optionIdValue);
                    }

                }

                if(setofCorrectAnswerOptions <> null && mapofoptionIdandcorrectanswer <> null && setofCorrectAnswerOptions.size() == mapofoptionIdandcorrectanswer.keyset().size())
                    userExamQuestion.isCorrectAnswer__c = true;
                if(setofWrongOptions <> null && setofWrongOptions.size()>0)
                    userExamQuestion.isCorrectAnswer__c = false;
            }else{
                userExamQuestion.isCorrectAnswer__c = false;
            }
        }
        //in case of matching question different approach
        if(QuestionsandAnswers.questionType == Matching_Type) {

            userExamQuestion.User_Answer__c = matchingTypeAnswerSequence;
            if(String.isNotBlank(matchingTypeAnswerSequence)){
                userExamQuestion.isCorrectAnswer__c = false;
                for(String answerSet: matchingTypeAnswerSequence.split(',')){
                    String[] s = answerSet.split('#');
                    if(s.size() == 2){
                        if(s[0] == s[1].split('@')[0] && s[1].split('@')[1] == 'y' ){
                            userExamQuestion.isCorrectAnswer__c = true;
                        }else{
                            userExamQuestion.isCorrectAnswer__c = false;
                        }
                    }else{
                        userExamQuestion.isCorrectAnswer__c = false;
                    }

                }
            }
        }

        if(QuestionsandAnswers.questionType == Category_Matching_Type) {
            system.debug('***userExamQuestion.User_Answer__c***'+userExamQuestion.User_Answer__c);
            userExamQuestion.isCorrectAnswer__c = false;
            system.debug('listofCategoryMatchingWrapperStore'+listofCategoryMatchingWrapper);
            List<String> listofallOptionsWithCategorySelection = new List<String>();
            Map<String,String> mapofPreviousOption = new Map<String,String>();
            String previousAnswer = userExamQuestion.User_Answer__c;
            if(previousAnswer <> null && previousAnswer <> ''){
                for(String previousAnsweroption : previousAnswer.split(';')){

                    mapofPreviousOption.put(previousAnsweroption.substring(0,18),previousAnsweroption.substring(19,previousAnsweroption.length()));
                }

            }
            Map<String,String> mapofcurrentSeletionOption = new Map<String,String>();
            if(categoryMatchingParaminController <> null && categoryMatchingParaminController<> ''){
                for(String currentSelectionOption : categoryMatchingParaminController.split(';')){
                    mapofcurrentSeletionOption.put(currentSelectionOption.substring(0,18),currentSelectionOption.substring(19,currentSelectionOption.length()));
                }
            }

            Map<String,String> finalMapofSelection = new Map<String,String>();
            //if greater number of current selection
            if( mapofcurrentSeletionOption.keyset()<> null && mapofcurrentSeletionOption.keyset().size()>0){
                for(String optionIdKey : mapofcurrentSeletionOption.keyset()){
                    finalMapofSelection.put(optionIdKey,mapofcurrentSeletionOption.get(optionIdKey));
                }

            }
            system.debug('*******finalMapofSelection1******'+finalMapofSelection);
            if(mapofPreviousOption.keyset() <> null && mapofPreviousOption.keyset().size()>0){
                for(String optionIdKey : mapofPreviousOption.keyset()){
                    if(!finalMapofSelection.containsKey(optionIdKey))
                        finalMapofSelection.put(optionIdKey,mapofPreviousOption.get(optionIdKey));
                }
            }
            // comment out block of code below to change data type of option_value__c and right_option_value__c
            for(Edgeforce_Question_Options__c localOption : listofOptions){
                if(localOption.Option_Value__c <> null && localOption.Option_Value__c <> ''){
                    if(!finalMapofSelection.ContainsKey(localOption.Id)){
                        finalMapofSelection.put(localOption.id,'None');
                    }
                }

            }

            system.debug('*******finalMapofSelection2******'+finalMapofSelection);
            String userAnswer = '';
            for(String optionIdValue : finalMapofSelection.keyset()){
                if(userAnswer ==''){
                    userAnswer = optionIdValue+'#'+finalMapofSelection.get(optionIdValue);
                }else{
                    userAnswer = userAnswer+';'+ optionIdValue+'#'+finalMapofSelection.get(optionIdValue);
                }

            }
            userExamQuestion.User_Answer__c = userAnswer;
            system.debug('* mapofoptionidandOptions***'+mapofoptionidandOptions );
            system.debug('**finalMapofSelection**'+ finalMapofSelection );
            Integer trueCount=0;
            Integer totalCount=0;

            
            // comment out block of code below to change data type of option_value__c and right_option_value__c
            for(Edgeforce_Question_Options__c localOption : listofOptions){
                if(localOption.Option_Value__c <> null && localOption.Option_Value__c  <> ''){
                    String rightOptValue =  mapofoptionidandOptions.get(localOption.Id).Right_Option_Value__c ;
                    String categoryValue = finalMapofSelection.get(localOption.Id);
                    if(rightOptValue=='' || rightOptValue== null)
                        rightOptValue = 'None';
                    if(categoryValue=='' || categoryValue== null)
                        categoryValue ='None';
                    system.debug(totalCount+'rightOptValue***'+rightOptValue);
                    system.debug(totalCount+'categoryValue***'+categoryValue);
                    totalCount = totalCount+1;
                    if(rightOptValue == categoryValue){
                        trueCount = trueCount+1;
                    }
                }
            }

            system.debug('* totalCount***'+totalCount );
            system.debug('* trueCount***'+trueCount );
            if(totalCount > 0 && totalCount == trueCount){
                userExamQuestion.isCorrectAnswer__c = true;
            }

        }

        //update original data for selection
        if(userExamQuestion.User_Answer__c <> null && userExamQuestion.User_Answer__c <> ''){
            if(QuestionsandAnswers.questionType == True_False_Type || QuestionsandAnswers.questionType== Single_Choice_Type){
                userExamQuestion.User_Selected_Answer__c = mapofoptionidandOptions.get(userExamQuestion.User_Answer__c).Option_Value__c;
            }else if(QuestionsandAnswers.questionType == Multiple_Choice_Type){
                List<String> listofMCQOptionsData = new  List<String>();
                for(String selectedOptionId : userExamQuestion.User_Answer__c.split('#')){
                    if(mapofoptionidandOptions.containskey(selectedOptionId)){
                        listofMCQOptionsData.add(mapofoptionidandOptions.get(selectedOptionId).Option_Value__c);
                    }
                }
                userExamQuestion.User_Selected_Answer__c = String.join(listofMCQOptionsData, ' ; ' );
            }else if(QuestionsandAnswers.questionType == Category_Matching_Type){
                List<String> listoftermsAndCategory = new  List<String>();
                for(String termIdAndCategory : userExamQuestion.User_Answer__c.split(';')){
                    if(termIdAndCategory <> null){
                        String termAndCategry;
                        if(mapofoptionidandOptions.containskey(termIdAndCategory.substring(0,18))){
                            termAndCategry = mapofoptionidandOptions.get(termIdAndCategory.substring(0,18)).Option_Value__c+' -- '+termIdAndCategory.substring(19,termIdAndCategory.length());
                        }
                        listoftermsAndCategory.add(termAndCategry);
                    }

                }
                if(listoftermsAndCategory <> null && listoftermsAndCategory.size()>0){
                    userExamQuestion.User_Selected_Answer__c = String.join(listoftermsAndCategory,' ; ');
                }
            }else if(QuestionsandAnswers.questionType == Matching_Type) {
                List<String> listOfMatchedItem = new  List<String>();
                String leftSide = '';
                String rightSide = '';
                for(String matchedRow : userExamQuestion.User_Answer__c.split(',')){
                    if(matchedRow <> null){
                        String leftAndRight = '';
                        String [] matchedRowArray  = new String[]{};
                        matchedRowArray = matchedRow.split('#');
                                if(matchedRowArray.size()>0){
                                        leftSide = matchedRowArray[0];
                                        if(matchedRowArray.size()>1){
                                                rightSide = matchedRowArray[1].split('@')[0];
                                        }
                                }
                                if(mapofoptionidandOptions.containskey(leftSide) && mapofoptionidandOptions.containskey(rightSide) && leftSide <> '' && rightSide <> ''){
                                    leftAndRight = mapofoptionidandOptions.get(leftSide).Option_Value__c+' -- '+mapofoptionidandOptions.get(rightSide).Right_Option_Value__c;
                                }
                         listOfMatchedItem.add(leftAndRight);
                        }

                }
                if(listOfMatchedItem.size()>0){
                    userExamQuestion.User_Selected_Answer__c = String.join(listOfMatchedItem,' , ');
                }
            }
        }

        try{
            Database.update(userExamQuestion);
        }catch(Exception e){
            // ApexAuditLog.createLogAndSave('AssessmentController','storeSelection', e.getStackTraceString(), e);
        }
        //system.debug('mapofsequenceandSelections**store**'+ mapofsequenceandSelections);
    }


    //method that returns specific exam data based on id
    public Edgeforce_Assessment__c getExamDetailsbyId(String examRecordId){


        List<Edgeforce_Assessment__c> listofLocalExams = new List<Edgeforce_Assessment__c>();
        for(Edgeforce_Assessment__c selectedExamDetails : [Select Total_Required_Questions__c,Enforce_Time_Limit__c , createdDate,Total_Associated_Questions__c, Time_Limit__c, Status__c, Passing_Grade__c,Max_Set__c, Name, Id
                                                 From Edgeforce_Assessment__c
                                                 Where  id =:examRecordId]){

                                                     if(selectedExamDetails <> null){
                                                         listofLocalExams.add(selectedExamDetails);
                                                     }
                                                 }
        if(listofLocalExams <> null && listofLocalExams.size()>0)
            return listofLocalExams[0];
        else
            return null;
    }

    //this method will return user exam tracker details based on ID
    public Edgeforce_Student_Assessment__c getUserExamDetails(String examTrackerId){

        List<Edgeforce_Student_Assessment__c> listofLocalUserExams = new List<Edgeforce_Student_Assessment__c>();
        for(Edgeforce_Student_Assessment__c userExamTrakerData : [Select  User__c,Submitted_Time__c, Assessment__c,isSubmitted__C, Assessment_Notes__c,End_Time__c, Score__c, Name, Id, Grade__c,Assessment__r.Passing_Grade__c // Added by Hemlata -S-195423
                                                        From Edgeforce_Student_Assessment__c
                                                        Where  id =:examTrackerId]){//Total_Correct_Answer__c

                                                            if(userExamTrakerData <> null){
                                                                listofLocalUserExams.add(userExamTrakerData);
                                                            }
                                                        }
        if(listofLocalUserExams <> null && listofLocalUserExams.size()>0)
            return listofLocalUserExams[0];
        else
            return null;
    }

    //this method will process list of questions of random selected set for  exam
    public List<Edgeforce_Questions__c> processRandomQuestionsforUser(Edgeforce_Assessment__c examRecord){

        assessmentSetNumber = '1';
        integer maxSetvalue = 1;
        List<Edgeforce_Questions__c> listoflocalquestionsforexamset = new  List<Edgeforce_Questions__c>();
        List<Edgeforce_Questions__c> finalListofQuestions = new List<Edgeforce_Questions__c>();
        
        if(examRecord <> null && examRecord.Max_Set__c <> null && examRecord.Max_Set__c <> 0){
            //commented as no need to randumizing the set as user will start always with set 1
            if(examRecord.Max_Set__c <> null){
              maxSetvalue = Integer.valueof(examRecord.Max_Set__c);
            }
              //D002
            //check if already this user attempt for this exam
            for(Edgeforce_Student_Assessment__c previousUserExamData : [Select  User__c,Assessment__c,Assessment_Notes__c,End_Time__c ,Set__c
                                                              From Edgeforce_Student_Assessment__c
                                                              Where Assessment__c =:examRecord.Id and  User__c=: userinfo.getUserId() order by LastModifiedDate DESC limit 1]){
                                                                  if(previousUserExamData <> null && previousUserExamData.Set__c <> null){
                                                                    if(maxSetvalue >= previousUserExamData.Set__c+1){
                                                                      assessmentSetNumber =   String.valueof(previousUserExamData.Set__c+1);

                                                                    }
                                                                  }
                                                              }
         
            //in case assessment set number exceed max set number we again start from set 1
            //if(Integer.valueof(assessmentSetNumber) > Integer.valueof(maxSetvalue))
               // assessmentSetNumber = '1';

            Integer limitValue = Integer.valueof(examRecord.Total_Required_Questions__c );
            for(Edgeforce_Questions__c examQuestion : [Select  Title__c, Status__c, Question_Type__c,Set__c, Name, Id, Assessment__c
                                             From Edgeforce_Questions__c
                                             Where Assessment__c =: examRecord.Id and Set__c =:assessmentSetNumber and Status__c=:'Active']){
                                                 if(examQuestion <> null) { //Total_Correct_Answer__c
                                                     listoflocalquestionsforexamset.add(examQuestion);
                                                     if(listoflocalquestionsforexamset.size()==limitValue)
                                                         break;
                                                 }

                                             }



        }
        //random list item generator
        List<Sobject> randomQuestionsList  = EdgeforceAssessmentController.processRandumList(listoflocalquestionsforexamset);
        finalListofQuestions =randomQuestionsList;
        return finalListofQuestions;

    }
    //review back button action
    public pagereference back(){
        showReviewPanel = false;
        return null;
    }
    //process final submit
    public pagereference processSubmit(){
        storeSelection();
        //assuming all question will have marks 1

        Edgeforce_Student_Assessment__c tobeSubmittedAssessment = new Edgeforce_Student_Assessment__c();
        tobeSubmittedAssessment.id = userExamid;
        tobeSubmittedAssessment.isSubmitted__c = true;
        tobeSubmittedAssessment.Submitted_Time__c = system.now();
        try{
          Database.update(tobeSubmittedAssessment);

          //Added By Sudhir Task Ref. T-214224
          tobeSubmittedAssessment = [SELECT Grade__c FROM Edgeforce_Student_Assessment__c WHERE Id = :tobeSubmittedAssessment.Id];

          if(STUDENT_GRADE.equalsIgnoreCase(tobeSubmittedAssessment.Grade__c)) {
              List<Asset_Progress__c> listAssetProgress = [SELECT Date_Completed__c, Status__c,Asset__r.Parent__c
                                                            FROM Asset_Progress__c
                                                              WHERE Asset__r.Assessment__c = :examInQAPage.Id 
                                                                AND Training_User__r.User__c = :UserInfo.getUserId() limit 1];
                List<Asset_Progress__c> listParentAssetProgress = new List<Asset_Progress__c>(); 
        //Added by: Nargis M,Cognizant AM Team for Dual tree issue
                for(Asset_Progress__c assetProgress : listAssetProgress)
                {
                    if(assetProgress.Asset__r.Parent__c != null)
                    {
                        listParentAssetProgress = [SELECT Date_Completed__c, Status__c,Asset__r.Parent__c
                                                            FROM Asset_Progress__c
                                                              WHERE Asset__c =:assetProgress.Asset__r.Parent__c
                                                                AND Training_User__r.User__c = :UserInfo.getUserId() limit 1];
                        
                    }
                
                }       
                if(listParentAssetProgress.size() > 0)
                {
                    listAssetProgress.add(listParentAssetProgress[0]);
                }   
                                                                
                for(Asset_Progress__c assetProgress : listAssetProgress) {

                  assetProgress.Status__c = ASSET_PROGRESS_STATUS_COMPLETE;
                  assetProgress.Date_Completed__c = System.now();
                  assetProgress.Percent_Complete__c = 100;
                }
                update listAssetProgress;
                 // START S-195423 - By Hemlata


          }  else {  
                //if (IntranetUtility.isMedicalUser()) { //S-213243 [hemant 5/7/2014] 
                listOfWrongAnswers = [SELECT Id, isCorrectAnswer__C, Sequence__c,Student_Assessment__c FROM Edgeforce_Student_Assessment_Questions__c WHERE Student_Assessment__c = :tobeSubmittedAssessment.Id and isCorrectAnswer__C= false order by Sequence__c ASC ];
                mapofMissedSequenceandQuestions = new Map<Integer,Edgeforce_Questions__c>();
                for (Edgeforce_Student_Assessment_Questions__c localQuestionData : listOfWrongAnswers) {
                   if (mapofSequenceandQuestions.containsKey( Integer.valueof(localQuestionData.Sequence__c))) {
                        Integer sequence  = Integer.valueof(localQuestionData.Sequence__c);
                        mapofMissedSequenceandQuestions.put(sequence,mapofSequenceandQuestions.get(sequence));
                   }
                }
            //} //S-213243 [hemant 5/7/2014]
          }
            // END S-195423 - By Hemlata

            //End Here

        } catch(Exception e){

            // ApexAuditLog.createLogAndSave('AssessmentController','processSubmit', e.getStackTraceString(), e);
        }


        userExaminQAPage = getUserExamDetails(userExamid);
        showFinalResultStatus(userExamid);
        return null;
    }

    public List<Integer> listofAllSequenceforReviewPage {get;set;}
    //review all
    public pagereference processReview(){

        storeSelection();
        mapofSequenceandUserExamQuestions = new  Map<Integer,Edgeforce_Student_Assessment_Questions__c>();
        listofAllSequenceforReviewPage = new  List<Integer>();
        listofUserExamQuestionsforReview = new List<Edgeforce_Student_Assessment_Questions__c>();
        set<Edgeforce_Student_Assessment_Questions__c> setofreviews = new   set<Edgeforce_Student_Assessment_Questions__c>();
        for(Edgeforce_Student_Assessment_Questions__c userExamQuestionsDataforReview : [Select isCorrectAnswer__c, Student_Assessment__c,CreatedDate, User_Answer__c, Sequence__c, Questions__c, Questions__r.Question_Type__c, Name, Id ,ReviewLater__c
                                                                              From Edgeforce_Student_Assessment_Questions__c
                                                                              Where Student_Assessment__c=: userExamid ]){
                                                                                  if(userExamQuestionsDataforReview <> null){
                                                                                      mapofSequenceandUserExamQuestions.put(Integer.valueof(userExamQuestionsDataforReview.Sequence__c),userExamQuestionsDataforReview);
                                                                                  }
                                                                              }
        for(Integer sequence : mapofSequenceandUserExamQuestions.keyset()){
            listofAllSequenceforReviewPage.add(sequence);
        }
        listofAllSequenceforReviewPage.sort();
        //listofUserExamQuestionsforReview.addall(setofreviews);
        // system.debug('listofUserExamQuestionsforReview'+listofUserExamQuestionsforReview);
        showReviewPanel = true;
        return null;
    }

    public void gotoReviewQuestion(){

        system.debug('reviewseq***'+reviewsequenceinController);

        if(reviewsequenceinController <>null && reviewsequenceinController <> ''){
            Integer sequenceNumber = Integer.valueof(reviewsequenceinController);
            if(mapofSequenceandQuestions.containskey(sequenceNumber)){
                getOptionsforQuestions(mapofSequenceandQuestions.get(sequenceNumber).Id);
                QuestionsandAnswers = new processExamQA(sequenceNumber,(mapofSequenceandQuestions.get(sequenceNumber)).Title__c,(mapofSequenceandQuestions.get(sequenceNumber)).Question_Type__c);
                processStateonUI(sequenceNumber);
            }
            showReviewPanel =  false;
            isReadyforSubmit = false;
            if(!mapofSequenceandQuestions.containskey(sequenceNumber)){
                isReadyforSubmit = true;
            }

            timerValue = timerDatetime.getTime()-system.now().gettime();

        }
    }


    public class CategoryMatchingWrapper{

        public String optionId{get;set;}//option Id
        public String selectedCategoryoptionId{get;set;}//the id of option for which category is selected

        public CategoryMatchingWrapper(String inputOptionId,String inputSelectedCategoryoptionId){

            this.optionId = inputOptionId;
            this.selectedCategoryoptionId = inputSelectedCategoryoptionId;
        }

    }

    //this method will generate random list items of a list
    public  static List<Sobject> processRandumList(List<Sobject> inputList){

        List<Sobject> processList = new   List<Sobject>();
        processList.addall(inputList);
        system.debug('**processList**'+processList);
        if(processList <> null){
            for (Integer i = 1; i < processList.size(); i++) {
                Integer j = Integer.valueof(Math.floor(Math.random()*(1+i)));  // choose j in [0..i]
                if (j != i) {
                    Sobject t;
                    t = processList[i];                        // swap list[i] and list[j]
                    processList[i] = processList[j];
                    processList[j] = t;
                }
            }

        }
        return processList;
    }


    public void showFinalResultStatus(String studentAssessmentRecordId){

    }



    public pagereference closeandRedirect(){
        Pagereference redirectPageName;
        //D001
        for(Asset__c localAsset : [SELECT Id, Course__c,Assessment__c,parent__c FROM Asset__c Where Assessment__c=: examInQAPage.Id]){
            if(localAsset <> null && localAsset.Course__c <> null){
                   redirectPageName = Page.IntranetCourseDetail;
                   redirectPageName.getParameters().put('Id',localAsset.Course__c);
               }else{
                redirectPageName = Page.EdgeforceAssessmentLaunch;


            }
            if (redirectPageName != null) {
                redirectPageName.setRedirect(true);
            }    
        }


        return redirectPageName;

    }



// START S-195423 - By Hemlata
     public pagereference onPassRedirect(){
       trainingUser = getTrainingUser();
        Pagereference redirectPageName;
        //D001
        List<Asset__c> localAssets = new List<Asset__c>([SELECT Id, Course__c,Assessment__c FROM Asset__c Where Assessment__c=:examInQAPage.Id]);
            if(localAssets <> null && localAssets.size() > 0){
                 redirectPageName = getCourseToRedirect(localAssets[0].Course__c);
            }else{
                redirectPageName = Page.EdgeforceAssessmentLaunch;
            }
        if (redirectPageName != null) {     
            redirectPageName.setRedirect(true); 
        }    
        return redirectPageName;

    }
    
     public void gotoMissedQuestion(){
        userExaminQAPage.issubmitted__c = false;
        update userExaminQAPage;
        isMissed=true;
        system.debug('reviewseq***'+missedsequenceinController);
         List<Integer> SequenceNos = new List<Integer>();
            for (Edgeforce_Student_Assessment_Questions__c wrongQuestion: listOfWrongAnswers) {
                SequenceNos.add(Integer.valueof(wrongQuestion.Sequence__c));
            }
        if(missedsequenceinController <>null && missedsequenceinController <> ''){
            Integer sequenceNumber = Integer.valueof(missedsequenceinController);
            if(mapofMissedSequenceandQuestions.containskey(sequenceNumber)){
                getOptionsforQuestions(mapofMissedSequenceandQuestions.get(sequenceNumber).Id);
                QuestionsandAnswers = new processExamQA(sequenceNumber,(mapofMissedSequenceandQuestions.get(sequenceNumber)).Title__c,(mapofSequenceandQuestions.get(sequenceNumber)).Question_Type__c);
                system.debug('QuestionsandAnswers***'+QuestionsandAnswers );
                processStateonUI(sequenceNumber);
            }
            showReviewPanel =  false;
            isReadyforSubmit = false;
             PreviousDisabled = false;
             SequenceNos.sort();
            if (SequenceNos[SequenceNos.size()-1] == sequenceNumber) {
               isReadyforSubmit = true;
               
            }
            system.debug(SequenceNos[0]);
             system.debug(sequenceNumber);
            if (SequenceNos[0] == sequenceNumber) {
               PreviousDisabled = true;
               system.debug(PreviousDisabled );
            }
            timerValue = timerDatetime.getTime()-system.now().gettime();

        }
    }
    
    private PageReference getCourseToRedirect(String courseId) {
        Set<Id> courseIds = new Set<Id> {courseId};
        List<Course_Progress__c> listCourseProgress = getProgressList(courseIds);
                for(Course_Progress__c courseProgress : listCourseProgress) {
                  system.debug('courseProgress***'+courseProgress);
                    
                  if (courseProgress.Status__c == 'Complete') {
                    system.debug('courseProgress***'+courseProgress);
                    return getNextCourseInModule(courseId);
                    break;
                  }
                }
                return new PageReference('/apex/IntranetCourseDetail?id='+courseId);
    }
    
    private pageReference getNextCourseInModule(String courseId) {
        String moduleId;
        String courseSortOrder;
        PageReference pageRef;
        List<Course_Module__c> cModuleList = [SELECT Id, sort_order__c, module__c, module__r.Name,module__r.Curriculum__c, module__r.curriculum__r.Name, Course__c FROM Course_Module__c WHERE Course__c = :courseId];
        if (cModuleList != null && cModuleList.size() >= 1) {
             courseSortOrder = cModuleList[0].sort_order__c;
             moduleId = cModuleList[0].module__c ;
        }
        if (courseSortOrder != null) {  
            String sortOrder = String.valueOf(Integer.ValueOf(courseSortOrder)+1);  
             
            List<Course_Module__c> courseList = new List<Course_Module__c>([SELECT  Course__r.Status__c,
                Course__r.Start_Date__c, Sort_Order__c, Course__r.Published_Date__c,Course__r.Name,  Module__c
                                             FROM Course_Module__c WHERE Module__c = :moduleId
                                              AND Course__r.IsPublished__c = true
                                              AND Course__c != null 
                                              AND (Course__r.Region__c = null OR Course__r.Region__c = :trainingUser.Region__c)
                                            ORDER By Sort_Order__c ASC]);
            Set<Id> courseIds = new Set<Id>();
            for(Course_Module__c courseModule : courseList) {
                courseIds.add(courseModule.Course__c);
            } // for      
            List<Course_Progress__c> courseProgressList = getProgressList(courseIds);           
            for(Course_Progress__c courseProgress : courseProgressList) {
                if(!courseAndCourseProgressMap.containsKey(courseProgress.Course__c)) {
                    courseAndCourseProgressMap.put(courseProgress.Course__c, courseProgress);
                }
            } // for    
            for(Course_Module__c courseModule : courseList) {   
                 if(courseAndCourseProgressMap.containsKey(courseModule.Course__c) && courseModule.Sort_Order__c == sortOrder) {
                    pageRef = new PageReference('/apex/IntranetCourseDetail?id='+courseModule.Course__c);
                    system.debug('pageRef ***'+pageRef);
                    return pageRef;
                 } else if (!courseAndCourseProgressMap.containsKey(courseModule.Course__c) && courseModule.Sort_Order__c == sortOrder) {
                     sortOrder = String.valueOf(Integer.ValueOf(sortOrder)+1);
                 }  
                       
            } // for
            
        }// if  
        if (moduleId != null) {
            pageRef = new PageReference('/apex/IntranetModuleDetail?id='+moduleId); 
        }     
        return pageRef;      
    }
    
    private List<Course_Progress__c> getProgressList(Set<Id> courseIds) {
        return new List<Course_Progress__c> ([SELECT Id, Due_Date__c, Date_Completed__c, Training_User__c, Percent_Complete__c,Enrollment_Type__c, Date_Started__c, Course__c, Status__c, Region_Lock__c
                                                       FROM Course_Progress__c
                                                      WHERE Course__c IN :courseIds
                                                        AND Course__r.IsPublished__c = true
                                                        AND Training_User__c = :trainingUser.Id]);

    }
    
     public Training_User__c getTrainingUser() {
        Training_User__c trainingUser;
        List<Training_User__c> trainingUserList = [SELECT id, Language__c, Region__c
                                                    FROM Training_User__c
                                                    WHERE User__c = :Userinfo.getUserId() Limit 1];
        if(trainingUserList != null && trainingUserList.size() > 0){
        trainingUser=trainingUserList[0];
        }
        else{
        trainingUser = new Training_User__c();
        trainingUser.User__c = Userinfo.getUserID();
        insert trainingUser;
        }
        return trainingUser;
    }
   // END S-195423
}