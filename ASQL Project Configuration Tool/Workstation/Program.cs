using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Workstation
{
    class Program
    {
        int LampAssembled = 0;

        static void Main(string[] args)
        {

            try
            {
                if(args.Length !=1)
                {
                    Console.WriteLine("Usage: Workstation.exe [new|normal|experienced]");
                    System.Environment.Exit(1);
                }
                //args at [0] will contain the worker type hence the length of args is 1
                string worker = args[0].ToLower();
                if(worker != "new" && worker != "normal" && worker != "experienced")
                {
                    Console.WriteLine("Usage: Workstation.exe [new|normal|experienced]");
                    System.Environment.Exit(1);
                }

                Program program = new Program();
                int timeScale = program.RetrieveTimeScale();


                int workStationId = program.AddNewWorkStation(worker);
                if (workStationId == 0)
                {
                    Console.WriteLine("No Station Available!");
                    return;
                }
                else if (workStationId == -1)
                {
                    System.Environment.Exit(1);
                }
                else
                {
                    Console.WriteLine("Added New Workstation: " + workStationId.ToString());
                }
                

                Random random = new Random();
                while(true)
                {
                    program.MakeLamp(worker, timeScale, random);
                    program.AddLamp(workStationId);
                }

            }
            catch (Exception error)
            {
                Console.WriteLine("Error: " + error.Message);
                System.Environment.Exit(1);
            }
        }

        void AddLamp(int WorkStationID)
        {
            //WorkStationID = 1;
            WorkStationID = 0;
            using(SqlConnection connection = new SqlConnection())
            {
                connection.ConnectionString = ConfigurationManager.ConnectionStrings["Conn"].ToString();
                connection.Open();

                //https://stackoverflow.com/questions/1260952/how-to-execute-a-stored-procedure-within-c-sharp-program
                using (SqlCommand command = new SqlCommand("[ASQLProject].[dbo].[AddLamp]", connection) { CommandType = CommandType.StoredProcedure })
                {
                    command.Parameters.Add("@StationID", SqlDbType.Int).Value = WorkStationID;
                   
                    using (SqlDataReader queryResults = command.ExecuteReader())
                    {
                        var schemaTable = queryResults.GetSchemaTable();
                        foreach (DataRow row in schemaTable.Rows)
                        {
                            foreach (DataColumn col in schemaTable.Columns)
                            {
                                Console.WriteLine(string.Format("{0}={1}", col.ColumnName, row[col]));
                            }
                        }
                        queryResults.Read();
                        Console.WriteLine(string.Format("Query Result: {0}", queryResults.GetValue(0)));
                        WorkStationID = ((int)queryResults.GetValue(0));
                    }
                }
            }
        }

        bool MakeLamp (string typeOfWorker, int timeScale, Random randNumGenerator)
        {
            //this variable is in seconds since we are going to compare the time to build a lamp with super worker
            //calculating it in miliseconds as the sleep function takes miliseconds
            int baseLineTimeInMiliSeconds = 60*1000;
            //We are going to decide wheter we want +10% or -10%
            int coinFlip = randNumGenerator.Next(2);
            if (coinFlip == 1)
            {
                baseLineTimeInMiliSeconds += (int)(baseLineTimeInMiliSeconds * 0.1);
            }
            else
            {
                baseLineTimeInMiliSeconds -= (int)(baseLineTimeInMiliSeconds * 0.1);
            }

            int TimeTakenToBuild = 0;

            switch(typeOfWorker)
            {
                case "new":
                    //Since new worker takes upt0 50% more time compare to experienced worker
                    TimeTakenToBuild = baseLineTimeInMiliSeconds + (int)(baseLineTimeInMiliSeconds * 0.5);
                    break;
                case "experienced":
                    TimeTakenToBuild = baseLineTimeInMiliSeconds - (int)(baseLineTimeInMiliSeconds * 0.15);
                    break;
                case "normal":
                    TimeTakenToBuild = baseLineTimeInMiliSeconds;
                    break;
                default:
                    throw new Exception("Invalid Worker Type!");

            }
            //We are putting this thread to sleep so that it can simulate the time it takes for a worker to finish a lamp
            System.Threading.Thread.Sleep(TimeTakenToBuild / timeScale);

            //each time this function gets called it will create a lamp
            LampAssembled++;

            return true;
        }

        int AddNewWorkStation(string WorkerType)
        {
            int workStationId = 0;
            using (SqlConnection connection = new SqlConnection())
            {
                connection.ConnectionString = ConfigurationManager.ConnectionStrings["Conn"].ToString();
                connection.Open();

                int workerTypeID = 0;
                using (SqlCommand command = new SqlCommand(string.Format("SELECT [StationWorkerTypeID] FROM [ASQLProject].[dbo].[StationWorkerType] WHERE [WorkerDescription]='{0}'", WorkerType),connection))
                {
                    
                    using (SqlDataReader queryResults = command.ExecuteReader())
                    {
                        queryResults.Read();
                        workerTypeID = (int)(queryResults.GetValue(0));
                    }
                }

                
                //https://stackoverflow.com/questions/1260952/how-to-execute-a-stored-procedure-within-c-sharp-program
                using (SqlCommand command = new SqlCommand("[ASQLProject].[dbo].[GetNewStation]", connection) { CommandType = CommandType.StoredProcedure })
                {
                    command.Parameters.Add("@WorkerType",SqlDbType.Int).Value=workerTypeID;
                    //connection.Open();
                    using (SqlDataReader queryResults = command.ExecuteReader())
                    {
                        queryResults.Read();
                        //Console.WriteLine(string.Format("Query Result: {0}", queryResults.GetValue(0)));
                        //workStationId = ((int)queryResults.GetValue(0));
                        if(workStationId == 0)
                        {
                            Console.WriteLine("No Stations Available!");
                        }
                    }
                }
            }

            return workStationId;
        }

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
    }
}
