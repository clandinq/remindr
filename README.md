# remindR
remindR is a system for automating academic conference, grant and presentation reminders using R on Mac OS X. Users can define what kind of reminders they want to obtain, which Gmail address to send the reminders from, and what addresses the reminders will be sent to.

## Basic usage
remindR helps project managers, researchers, research assistants and students keep track of deadlines related to academic projects. This system can send out four types of reminders:

1. **Future conference reminders**. These are reminders to check if future conferences have announced details that would allow to track them (deadlines, submission links, and descriptions).
2. **Conference deadlines**. Reminders to submit papers or abstracts to conferences.
3. **Upcoming presentations**. Reminders for upcoming presentations, including slide submission deadlines.
4. **Grant deadlines**. This can be useful both when applying for grants and when submitting grant deliverables.

## Set up
### Cloning the repo
First clone the repo locally into the desired project folder. This system works best with the folder structure defined by [Sean Higgins](https://seankhiggins.com/) in his [R guide](https://github.com/skhiggins/r_guide). For example, below is a brief example of the terminal commands to clone a project titled "Health RCT".

```r
cd Work/health_rct
git clone https://github.com/clandinq/remindr reminders
```
This will download 2 scripts, 5 csv files, this readme and a .Rproj file. 

### CSV files with conference, grant and presentation information
Users need to modify two sets of files to set up the reminder system. First, one to four CSV files containing details about conferences, grants and presentations, that will be used to send the reminders. The files and variables are:

1. `rem_future_conferences.csv`: Future conference reminders. 
    1. `deadline`: Estimated *date* the conference will take place.
    2. `description`: Description of the conference.
    3. `website`: Conference website.
2. `rem_conference_deadlines.csv`: Conference deadlines.
    1. `deadline`: Conference abstract or paper submission deadline.
    2. `notification`: Date notification on admission sent. Can be NA.
    3. `description`: Description of the conference.
    4. `questions`: Line indicating who to ask conference questions. Can be NA.
    5. `submission: Link to submit abstract or paper to.
    6. `dead_type`: *abstract* or *paper*.
    7. `website`: Conference website.
3. `rem_upcoming_presentations.csv`: Reminders for upcoming presentations, including slide submission deadlines.
    1. `deadline`: Upcoming presentation date or slide submission deadline.
    2. `dead_type`: *conference presentation* or *slide submission*.
    3. `description`: Description of the conference.
    4. `submission: Link to submit slides to. Can be NA if `dead_type`="conference presentation".
    5. `website`: Conference website.
4. `rem_grant_deadlines.csv`: Grant deadlines.
    1. `deadline`: Grant deadline.
    2. `description`: Description of the grant.
    3. `dead_type`: *deliverable*, *proposal* or other (cannot be NA).
    4. `details`: Details about what the submission requires
    5. `questions`: Line indicating who to ask conference questions. Can be NA.
    6. `submission: Link to submit grant deliverable/proposal/etc.

The four CSV files downloaded contain data examples, which must be overwritten before proceeding with the setup.

### Reminder parameters
Second, general project and specific reminder parameters need to be set in script `1_define_reminder_parameters.R`, which saves these parameters in `rem_parameters.csv` and sets up a repeating task with cronR. 

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

Once the data for the reminders has been filled out in the CSV files, and the parameters set in the first script, users can run `1_define_reminder_parameters.R` to conclude the setup of the reminder system.



