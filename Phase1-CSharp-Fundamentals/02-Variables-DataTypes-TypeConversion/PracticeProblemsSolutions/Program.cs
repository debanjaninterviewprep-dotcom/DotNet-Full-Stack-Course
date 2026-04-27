
using System;

namespace PracticeProblemsSolutions
{
    class Program
    {
        static void Main(string[] args)
        {
            // Problem 1: Variable Declarations and Printing
            int myInt = 42;
            double myDouble = 3.14;
            decimal myDecimal = 19.99m;
            float myFloat = 2.718f;
            long myLong = 123456789L;
            char myChar = 'A';
            bool myBool = true;
            string myString = "Hello, World!";
            Console.WriteLine($"Integer: {myInt}");
            Console.WriteLine($"Double: {myDouble}");
            Console.WriteLine($"Decimal: {myDecimal}");
            Console.WriteLine($"Float: {myFloat}");
            Console.WriteLine($"Long: {myLong}");
            Console.WriteLine($"Char: {myChar}");
            Console.WriteLine($"Boolean: {myBool}");
            Console.WriteLine($"String: {myString}");

            // Problem 2: Smart Type Converter
            Console.WriteLine("\n=== Smart Type Converter ===");
            Console.Write("Enter a string value: ");
            string? input = Console.ReadLine();
            if (int.TryParse(input, out int intValue))
                Console.WriteLine($"Conversion to int succeeded: {intValue}");
            else
                Console.WriteLine("Conversion to int failed.");
            if (double.TryParse(input, out double doubleValue))
                Console.WriteLine($"Conversion to double succeeded: {doubleValue}");
            else
                Console.WriteLine("Conversion to double failed.");
            if (bool.TryParse(input, out bool boolValue))
                Console.WriteLine($"Conversion to bool succeeded: {boolValue}");
            else
                Console.WriteLine("Conversion to bool failed.");

            // Problem 3: Salary Calculator
            Console.WriteLine("\n=== Salary Calculator ===");
            Console.Write("Enter employee's name: ");
            string? empName = Console.ReadLine();
            decimal hourlyRate = ReadDecimal("Enter hourly rate: ");
            decimal hoursWorked = ReadDecimal("Enter hours worked this week: ");
            decimal grossPay = hourlyRate * hoursWorked;
            decimal tax = grossPay * 0.2m;
            decimal netPay = grossPay - tax;
            Console.WriteLine();
            Console.WriteLine("Pay Slip");
            Console.WriteLine("--------");
            Console.WriteLine($"Employee: {empName}");
            Console.WriteLine($"Hourly Rate: {hourlyRate:C}");
            Console.WriteLine($"Hours Worked: {hoursWorked}");
            Console.WriteLine($"Gross Pay: {grossPay:C}");
            Console.WriteLine($"Tax (20%): {tax:C}");
            Console.WriteLine($"Net Pay: {netPay:C}");

            // Problem 4: Data Type Size Reporter
            Console.WriteLine("\n=== Data Type Size Reporter ===");
            Console.WriteLine("Data Type\tSize (Bytes)\tMin Value\t\t\tMax Value");
            Console.WriteLine("---------------------------------------------------------------");
            Console.WriteLine($"int\t\t{sizeof(int)}\t\t{int.MinValue}\t\t{int.MaxValue}");
            Console.WriteLine($"double\t\t{sizeof(double)}\t\t{double.MinValue}\t{double.MaxValue}");
            Console.WriteLine($"decimal\t{sizeof(decimal)}\t\t{decimal.MinValue}\t{decimal.MaxValue}");
            Console.WriteLine($"float\t\t{sizeof(float)}\t\t{float.MinValue}\t\t{float.MaxValue}");
            Console.WriteLine($"long\t\t{sizeof(long)}\t\t{long.MinValue}\t{long.MaxValue}");
            Console.WriteLine($"short\t\t{sizeof(short)}\t\t{short.MinValue}\t\t{short.MaxValue}");
            Console.WriteLine($"byte\t\t{sizeof(byte)}\t\t{byte.MinValue}\t\t{byte.MaxValue}");

            // Problem 5: Nullable Score Tracker
            Console.WriteLine("\n=== Nullable Score Tracker ===");
            int? mathScore = ReadNullableInt("Enter score for Math (or press Enter to skip): ");
            int? scienceScore = ReadNullableInt("Enter score for Science (or press Enter to skip): ");
            int? englishScore = ReadNullableInt("Enter score for English (or press Enter to skip): ");
            int?[] scores = { mathScore, scienceScore, englishScore };
            int gradedCount = 0;
            int totalScore = 0;
            foreach (var score in scores)
            {
                if (score.HasValue)
                {
                    gradedCount++;
                    totalScore += score.Value;
                }
            }
            double average = gradedCount > 0 ? (double)totalScore / gradedCount : 0;
            Console.WriteLine();
            Console.WriteLine("Report Card:");
            Console.WriteLine($"Math:    {(mathScore.HasValue ? mathScore.Value.ToString() : "Not Graded")}");
            Console.WriteLine($"Science: {(scienceScore.HasValue ? scienceScore.Value.ToString() : "Not Graded")}");
            Console.WriteLine($"English: {(englishScore.HasValue ? englishScore.Value.ToString() : "Not Graded")}");
            Console.WriteLine($"Average (graded only): {average:F2}");
            Console.WriteLine($"Subjects graded: {gradedCount}/3");
        }

        static decimal ReadDecimal(string prompt)
        {
            decimal value;
            Console.Write(prompt);
            while (!decimal.TryParse(Console.ReadLine(), out value))
            {
                Console.Write("Invalid input. " + prompt);
            }
            return value;
        }

        static int? ReadNullableInt(string prompt)
        {
            Console.Write(prompt);
            string? input = Console.ReadLine();
            if (string.IsNullOrWhiteSpace(input))
                return null;
            if (int.TryParse(input, out int value))
                return value;
            Console.WriteLine("Invalid input. Skipping.");
            return null;
        }
    }
}