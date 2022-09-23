# remindR
remindR is a system for automating academic project reminders using R on Mac and Windows. Users can define what kind of reminders they want to obtain, which Gmail address to send the reminders from, and which addresses the reminders will be sent to. This system can help project managers, researchers, research assistants and students keep track of deadlines related to academic projects, reducing the burden of tracking these events manually and the eliminating the possibility of making manual mistakes.

This system can send out four types of reminders:

1. **Future conference reminders**. These are reminders to check if future conferences have announced details that would allow to track them (deadlines, submission links, and descriptions).
2. **Conference deadlines**. Reminders to submit papers or abstracts to conferences.
3. **Upcoming presentations**. Reminders for upcoming presentations, including slide submission deadlines.
4. **Grant deadlines**. This can be useful both when applying for grants and when submitting grant deliverables.

## Set up
There are three steps for setting up the remindR system:
1. Clone the repo to your project folder
2. Fill out conference, grant and presentation information
3. Define reminder parameters

### 1. Clone the repo
First clone the repo locally into the desired project folder. This system works best with the folder structure defined by [Sean Higgins](https://seankhiggins.com/) in his [R guide](https://github.com/skhiggins/r_guide). The recommendation is to add the system to the Dropbox folder so that all project members (including those not using GitHub) can see programmed events in the reminder datasets. For example, below is a brief example of the terminal commands to clone a project titled "Health RCT".

```r
cd Work/health_rct
git clone https://github.com/clandinq/remindr reminders
```
This will download 2 scripts, 5 .xlsx files, this readme and a .Rproj file. 

### 2. Fill out Excel files with conference, grant and presentation information
You need to modify two sets of files to set up the reminder system. First, one to four .xlsx files containing details about conferences, grants and presentations, that will be used to send the reminders. The files and variables are:

1. `rem_future_conferences.xlsx`: **Future conference reminders**
    1. `deadline`: Estimated *date* the conference will take place in yyyy_mm_dd text format. This format is used to prevent Excel from automatically changing the date format.
    2. `description`: Description of the conference.
    3. `website`: Conference website.
2. `rem_conference_deadlines.xlsx`: **Conference deadlines**
    1. `deadline`: Conference abstract or paper submission deadline in yyyy_mm_dd text format.
    2. `notification`: Date notification on admission sent in yyyy_mm_dd text format. Can be NA.
    3. `description`: Description of the conference.
    4. `questions`: Line indicating who to ask conference questions. Can be NA.
    5. `submission: Link to submit abstract or paper to.
    6. `dead_type`: *abstract* or *paper*.
    7. `website`: Conference website.
3. `rem_upcoming_presentations.xlsx`: **Reminders for upcoming presentations**, including slide submission deadlines
    1. `deadline`: Upcoming presentation date or slide submission deadline in yyyy_mm_dd text format.
    2. `dead_type`: *conference presentation* or *slide submission*.
    3. `description`: Description of the conference.
    4. `submission: Link to submit slides to. Can be NA if `dead_type`="conference presentation".
    5. `website`: Conference website.
    6. `complete`: This variable defines whether reminders need to be sent or not. If all scheduled reminders have been sent, it is marked as complete (`complete = 1`). The default value is `complete = 0`. Set `complete = 1` in the Excel document if it is not necessary to send this set of reminders anymore (for example, when completing a submission before the final reminder).
4. `rem_grant_deadlines.xlsx`: **Grant deadlines**
    1. `deadline`: Grant deadline in yyyy_mm_dd text format.
    2. `description`: Description of the grant.
    3. `dead_type`: *deliverable*, *proposal* or other (cannot be NA).
    4. `details`: Details about what the submission requires
    5. `questions`: Line indicating who to ask conference questions. Can be NA.
    6. `submission: Link to submit grant deliverable/proposal/etc.

The four Excel files downloaded contain data examples, which must be overwritten before proceeding with the setup. You only need to modify the files for which you will send reminders. For example, if you will not be sending any grant deadline reminders, you can leave the template blank and simply select in the next step that you will not be sending these reminders out.

### 3. Define reminder parameters
Second, general project and specific reminder parameters need to be set in script `1_define_reminder_parameters.R`, which saves these parameters in `rem_parameters.xlsx` and sets up a repeating task with cronR. 

1. **General project parameters**. These apply for all reminders in a project.
   
   - `proj_name`: define a short project name to be used in email headers.
   - `email_from`: a Gmail address to send emails from.
   - `name_from`: name to use for email signature.
   - `secret_path`: absolute path to Gmail client secret. To obtain a Gmail API OAuth ID, follow the following steps:

     1. [Create a Google Cloud project](https://developers.google.com/workspace/guides/create-project).
     2. Open [Google Cloud Console](https://console.cloud.google.com/).
     3. At the top-left, click **Menu** > **APIs & Services** > **Credentials**.
     4. Click on **Create Credentials** > **OAuth client ID**. Select "Desktop app".
     5. Download client secret JSON file.

2. **Specific reminder parameters**. These are individual to each reminder.

   - `_activate`: boolean to define whether reminder will be active.
   - `_emails`: comma separated emails to send reminders to (e.g. "john.smith@gmail.com, jane.smith@hotmail.com").
   - `_freq`: comma separated number of days before deadline to send reminders (e.g. "1, 2, 5, 10").

Once the data for the reminders has been filled out in the Excel files, and the parameters set in the first script, you can run `1_define_reminder_parameters.R` to conclude the setup of the reminder system. 

## Regular usage
Once the initial set up has been completed, you can add conferences, grants and presentations by modifying the relevant Excel files.

To delete reminders:
- **Mac OS X**. Run the following commands in R:
    ```R
    pacman::p_load(cronR)
    cron_ls() # This lists out all the scheduled tasks
    cron_rm("name of task") # Insert the name of the reminder task you want to remove
    ``` 
- **Windows**. Run the following commands in R:
    ```R
    pacman::p_load(taskscheduleR)
    taskscheduler_ls() # This lists out all the scheduled tasks
    taskscheduler_delete("name of task") # Insert the name of the reminder task you want to remove
    ``` 
On Windows, it is necessary to delete a reminder before scheduling another reminder with the same name.

