## The challenge

In my [Shinydashboard application](https://iedeadata.org/iedea-harmonist/), the sidebar contains a menu of tabs that represent a workflow for the user.

![Shiny app sidebar menu](Step1.png)

The tab labelled Step 1 contains a Shiny fileInput prompt for users to browse and select files to upload to the application. In Step 2, an interactive data table displays the results of data quality checks performed on data uploaded in Step 1. In Step 3 users can generate reports summarizing the dataset and its quality. Authenticated users have the option in Step 4 to store the dataset in secure cloud storage for retrieval by investigators who requested data. Another optional tab leads users to interactive graphical exploration of the dataset. 

Since a Shiny app is technically a single webpage, using the browser's "back" button results in terminating the application. Users of my application might expect to be able to move through the steps with the browser navigation buttons as an alternative to the sidebar menu and would be horrified to realize that all data and data quality results were lost due to the innocent click of the back button. 
