/*
 *  FileName: MainWindow.xaml.cs 
 *  Project: Advanced SQL Project Milestone #1
 *  Date: Monday April 17th, 2018 
 *  Programmers: Humaira Siddiqa (5523840)
 *               Manuel Poppe Richter(7659402)
 *  Description: This is the Main Window file. It creates the application window that the user will be using, and contains
 *  the code for every event that the user can trigger in the applcation. This App allows the user to connect to the ASQL project database, and view and 
 * change the configuration settings of the configuration table. 
*/


using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Configuration;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Data.SqlClient;
using System.Data;

namespace ASQL_Project_Configuration_Tool
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();
            InitializeList();
        }

        // Name: InitializeList
        // Description: This method is called to initialize the list of configuration objects the user can choose from
        // Inputs: none
        // outputs: none 
        public void InitializeList()
        {
            // first, open up a connection to get all of the product class selections
            // Updates the chart to show the selected data to the user
            using (SqlConnection connection = new SqlConnection())
            {
                connection.ConnectionString = ConfigurationManager.ConnectionStrings["Conn"].ToString();

                // opening sql connection
                connection.Open();

                // create the string we are going to Query the Database with
                string query = "SELECT ConfigurationSetting FROM ConfigurationTable";
                // create the command we are going to use in order to execute the query
                SqlCommand currentCommand = new SqlCommand(query, connection);

                // get the results of the query and push it into the list
                using (SqlDataReader queryResults = currentCommand.ExecuteReader())
                {

                    // clear out the old list, then add the "All" option
                    ConfigurationListBox.Items.Clear();

                    // loop through every result
                    while (queryResults.Read())
                    {
                        // add the current product class into the combo box
                        ConfigurationListBox.Items.Add(queryResults.GetValue(0));

                    }

                }

                connection.Close();
            }
        }

        // Name: ConfigurationListBox_SelectionChanged
        // Description: This event is called whenever the user switches a selection in the configuration list
        // It resets the current value that is displayed to the user
        // Inputs: Object sender : reference to the control object that sent the event
        // RoutedEventArgs e: contians event data
        // outputs: void

        private void ConfigurationListBox_SelectionChanged(object sender, SelectionChangedEventArgs e)
        {
           
            // get the value that the user selected
            string value = ConfigurationListBox.SelectedItem.ToString();
            using (SqlConnection connection = new SqlConnection())
            {
                connection.ConnectionString = ConfigurationManager.ConnectionStrings["Conn"].ToString();

                // opening sql connection
                connection.Open();

              

                // create the string we are going to Query the Database with
                string query = "SELECT ConfigurationValue FROM ConfigurationTable WHERE ConfigurationSetting='" + value + "'";
                // create the command we are going to use in order to execute the query
                SqlCommand currentCommand = new SqlCommand(query, connection);

                // get the results of the query and push it into the list
                ValueDisplayTextBlock.Text = currentCommand.ExecuteScalar().ToString();
                
                

                

                connection.Close();
            }

            SetMaxMin(value);
            // clear the result label
            ResultLabel.Content = "";

            // clear the textbox for user input
            ValueTextBox.Text = "";
        }

        // Name: ChangeButtonClick
        // Description: This changes the value of the selected configuration setting to the one in the textbox
        // Inputs: Object sender : reference to the control object that sent the event
        // RoutedEventArgs e: contians event data
        // outputs: void
        private void ChangeButton_Click(object sender, RoutedEventArgs e)
        {
            // first, get the value that the user wishes to change the setting to
            int value = 0;

            bool result = Int32.TryParse(ValueTextBox.Text, out value);


            if (!result)
            {
                ResultLabel.Content = "Must enter a valid integer";
            }
            else
            {
                // the user has entered a valid integer. Attempt to update the database with the input
                using (SqlConnection connection = new SqlConnection())
                {
                    connection.ConnectionString = ConfigurationManager.ConnectionStrings["Conn"].ToString();

                    // opening sql connection
                    connection.Open();

                    // get the value that the user selected
                    string setting = ConfigurationListBox.SelectedItem.ToString();

                   
                    // create the command we are going to use in order to execute the query
                    SqlCommand currentCommand = new SqlCommand("ChangeSetting", connection);

                    currentCommand.CommandType = CommandType.StoredProcedure;

                    

                    currentCommand.Parameters.Add(new SqlParameter("@Name", setting));
                    currentCommand.Parameters.Add(new SqlParameter("@Value", value));


                    // setting up the return value of the query
                    var returnParameter = currentCommand.Parameters.Add("@FinalResult", SqlDbType.Int);
                    returnParameter.Direction = ParameterDirection.ReturnValue;

                    // get the results of the stored procedure
                    currentCommand.ExecuteNonQuery();
                    int QueryResult = (int) returnParameter.Value;



                    if (QueryResult == 0)
                    {
                        // All is well
                        ResultLabel.Content = "Value Changed Successfully";
                        // change the current value to reflect the users choice
                        ValueDisplayTextBlock.Text = value.ToString();

                    }
                    else
                    {
                        // All is not well
                        ResultLabel.Content = "Error: Value out of range for setting";
                    }

                    connection.Close();
                }
            }
        }


        // Name: DefaultButton_Click
        // Description: This event is called whenever the user clicks the DefaultButton.
        // It sends a command to the SQL database to reset the values to their default values
        // Inputs: Object sender : reference to the control object that sent the event
        // RoutedEventArgs e: contians event data
        // outputs: none
        private void DefaultButton_Click(object sender, RoutedEventArgs e)
        {
          
            using (SqlConnection connection = new SqlConnection())
            {
                // get the configuration string
                connection.ConnectionString = ConfigurationManager.ConnectionStrings["Conn"].ToString();

                // opening sql connection
                connection.Open();

                // create the command we are going to use in order to call the stored procedure
                SqlCommand currentCommand = new SqlCommand("SetDefaults", connection);

                currentCommand.CommandType = CommandType.StoredProcedure;

                // setting up the return value of the query
                var returnParameter = currentCommand.Parameters.Add("@FinalResult", SqlDbType.Int);
                returnParameter.Direction = ParameterDirection.ReturnValue;

                // get the results of the stored procedure
                currentCommand.ExecuteNonQuery();
                int QueryResult = (int)returnParameter.Value;

                if (QueryResult == 0)
                {
                    // All is well
                    ResultLabel.Content = "Defaults Reset";

                }
                else
                {
                    // All is not well
                    ResultLabel.Content = "An Error has occured: Values not changed";
                }

                connection.Close();
            }
        }

        // Name: SetMaxMin
        // Description: This method queries the database and updates the max and min textblock
        // with the appropriate values to match the setting entered
        // Input: string settingName: Name of the setting we want to update the max and min textBlocks with
        // outputs: void
        private void SetMaxMin(string settingName)
        {
            // set up the two quries we will need
            string query1 = "SELECT ConfigurationMax FROM ConfigurationTable WHERE ConfigurationSetting=" + "'" + settingName + "'";
            string query2 = "SELECT ConfigurationMin FROM ConfigurationTable WHERE ConfigurationSetting=" + "'" + settingName + "'";

            using (SqlConnection connection = new SqlConnection())
            {
                connection.ConnectionString = ConfigurationManager.ConnectionStrings["Conn"].ToString();

                // opening sql connection
                connection.Open();

                // create the command we are going to use in order to execute the query
                SqlCommand currentCommand = new SqlCommand(query1, connection);

                // get the results and update the appropriate textblock
               MaxTextBlock.Text = currentCommand.ExecuteScalar().ToString();


                // create the next command and update the min textblock
                currentCommand = new SqlCommand(query2, connection);
                MinTextBlock.Text = currentCommand.ExecuteScalar().ToString();

                connection.Close();
            }
        }
    }
}
