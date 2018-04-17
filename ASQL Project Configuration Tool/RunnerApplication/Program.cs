/*
* FILE			:		Program.cs
* PROJECT		:		PROG3070 - Kanban
* PROGRAMMER	:		Humaira Siddiqa (5523840)
*                       Manuel Poppe Richter(7659402)
* FIRST VERSION :		April 17th, 2018
* DESCRIPTION	:		This application has been created to do a simulation of different workstation
* of Kanban. This application will simulate the real time it takes for a runner to fill each bit periodically,
* however it will be a bit faster since simulation is faster than real time. It will also run a simulation
* of how each worker produces lamps and how fast they work. This file contains the code for the runners
* simulation where the run comes and re-fills the bit every five minutes.
*/

using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;

namespace RunnerApplication
{
    class Program
    {
        static void Main(string[] args)
        {
            try
            {
                Program program = new Program();

                Console.WriteLine("Runner Running. Press CTRL+C to exit.");
                while (true)
                {
                    int timeScale = program.RetrieveTimeScale();
                    int fiveMinutesInSeconds = 300; //converting five minutes to seconds
                    System.Threading.Thread.Sleep(fiveMinutesInSeconds / timeScale * 1000);
                    Console.WriteLine("Calling Runner Update Stored Procedure.");
                    program.CallRunnerUpdate();
                }
            }
            catch (Exception error)
            {
                Console.WriteLine("Error: {}" + error.Message);
                System.Environment.Exit(1);
            }
        }

        /// <summary>
        /// This function calculates the timescale for the runner. It collects the actual
        /// time scale from the database in order to do the simulation here.
        /// </summary>
        /// <returns> It returns an int</returns>
        int RetrieveTimeScale()
        {
            int timeScale = 0;
            using (SqlConnection connection = new SqlConnection())
            {
                connection.ConnectionString = ConfigurationManager.ConnectionStrings["Conn"].ToString();

                // opening sql connection
                connection.Open();

                // create the string we are going to Query the Database with
                string query = "  SELECT [ConfigurationTable].[ConfigurationValue] FROM [ASQLProject].[dbo].[ConfigurationTable] WHERE [ConfigurationSetting] = 'TimeScale'";
                // create the command we are going to use in order to execute the query
                SqlCommand currentCommand = new SqlCommand(query, connection);

                // get the results of the query and push it into the list
                using (SqlDataReader queryResults = currentCommand.ExecuteReader())
                {
                    queryResults.Read();
                    //Console.WriteLine(string.Format("Query Result: {0}", queryResults.GetValue(0)));
                    timeScale = ((int)queryResults.GetValue(0));
                }

                connection.Close();
            }
            return timeScale;
        }

        /// <summary>
        /// This function calls for runners update to get the current status of the runner.
        /// </summary>
        void CallRunnerUpdate()
        {
            using (SqlConnection connection = new SqlConnection())
            {
                connection.ConnectionString = ConfigurationManager.ConnectionStrings["Conn"].ToString();
                //https://stackoverflow.com/questions/1260952/how-to-execute-a-stored-procedure-within-c-sharp-program
                using (SqlCommand command = new SqlCommand("[ASQLProject].[dbo].[RunnerUpdate]", connection) { CommandType= CommandType.StoredProcedure})
                {
                    connection.Open();
                    command.ExecuteNonQuery();
                }
            }
        }
    }
}