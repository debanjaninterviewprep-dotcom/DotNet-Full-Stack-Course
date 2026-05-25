using System;
using System.Text;
using System.Text.RegularExpressions;

namespace PracticeProblemsSolutions
{
	class Program
	{
		static void Main(string[] args)
		{
			// ===============================
			// Problem 1: Array Statistics
			// ===============================
			// Read 5 numbers, calculate sum, average, min, max, and count above average without using LINQ Min/Max.

			Console.WriteLine("Problem 1: Array Statistics");
			int[] numbers = new int[5];

			for (int i = 0; i < numbers.Length; i++)
			{
				Console.Write($"Enter number {i + 1}: ");
				numbers[i] = int.Parse(Console.ReadLine());
			}

			int sum = 0;
			int min = numbers[0];
			int max = numbers[0];
			foreach (int num in numbers)
			{
				sum += num;
				if (num < min) min = num;
				if (num > max) max = num;
			}

			double average = (double)sum / numbers.Length;
			int countAboveAverage = 0;
			foreach (int num in numbers)
			{
				if (num > average) countAboveAverage++;
			}

			Console.WriteLine($"Sum: {sum}");
			Console.WriteLine($"Average: {average}");
			Console.WriteLine($"Minimum: {min}");
			Console.WriteLine($"Maximum: {max}");
			Console.WriteLine($"Count above average: {countAboveAverage}");

			// ===============================
			// Problem 2: Word Analyzer
			// ===============================
			// Analyze sentence for character/word count, vowels/consonants, uppercase/lowercase, reversed words, capitalized version.

			Console.WriteLine("\nProblem 2: Word Analyzer");
			Console.Write("Enter a sentence: ");
			string sentence = Console.ReadLine() ?? string.Empty;

			int totalCharsWithSpaces = sentence.Length;
			int totalCharsWithoutSpaces = 0;
			string[] words = sentence.Split(' ', StringSplitOptions.RemoveEmptyEntries);
			int wordCount = words.Length;
			int vowelCount = 0;
			int consonantCount = 0;
			int upperCaseCount = 0;
			int lowerCaseCount = 0;

			foreach (char c in sentence)
			{
				if (!char.IsWhiteSpace(c)) totalCharsWithoutSpaces++;

				if (char.IsLetter(c))
				{
					if ("AEIOUaeiou".IndexOf(c) >= 0) vowelCount++;
					else consonantCount++;

					if (char.IsUpper(c)) upperCaseCount++;
					if (char.IsLower(c)) lowerCaseCount++;
				}
			}

			// Reversed sentence (word by word)
			string reversedSentence = string.Empty;
			if (words.Length > 0)
			{
				string[] reversedWords = (string[])words.Clone();
				Array.Reverse(reversedWords);
				reversedSentence = string.Join(' ', reversedWords);
			}

			// Capitalized (first letter uppercase for each word)
			string capitalizedSentence = string.Empty;
			if (words.Length > 0)
			{
				string[] caps = new string[words.Length];
				for (int i = 0; i < words.Length; i++)
				{
					string w = words[i];
					if (w.Length == 0) { caps[i] = w; continue; }
					caps[i] = char.ToUpper(w[0]) + (w.Length > 1 ? w.Substring(1).ToLower() : string.Empty);
				}
				capitalizedSentence = string.Join(' ', caps);
			}

			Console.WriteLine("\n=== SENTENCE ANALYSIS ===");
			Console.WriteLine($"Original:     \"{sentence}\"");
			Console.WriteLine($"Characters:   {totalCharsWithSpaces} (with spaces), {totalCharsWithoutSpaces} (without)");
			Console.WriteLine($"Words:        {wordCount}");
			Console.WriteLine($"Vowels:       {vowelCount}");
			Console.WriteLine($"Consonants:   {consonantCount}");
			Console.WriteLine($"Uppercase:    {upperCaseCount}");
			Console.WriteLine($"Lowercase:    {lowerCaseCount}");
			Console.WriteLine($"Reversed:     \"{reversedSentence}\"");
			Console.WriteLine($"Capitalized:  \"{capitalizedSentence}\"");


			// ===============================
			// Problem 3: Matrix Operations
			// ===============================
			// Create 3x3 matrices, perform addition, transpose, calculate diagonal sum using nested for loops.

			Console.WriteLine("\nProblem 3: Matrix Operations");
			int[,] matrixA = new int[3, 3];
			Console.WriteLine("Enter values for Matrix A (3x3):");
			for (int i = 0; i < 3; i++)
			{
				for (int j = 0; j < 3; j++)
				{
					Console.Write($"A[{i},{j}]: ");
					matrixA[i, j] = int.Parse(Console.ReadLine());
				}
			}
			int[,] matrixB = new int[3, 3];
			Console.WriteLine("Enter values for Matrix B (3x3):");
			for (int i = 0; i < 3; i++)
			{
				for (int j = 0; j < 3; j++)
				{
					Console.Write($"B[{i},{j}]: ");
					matrixB[i, j] = int.Parse(Console.ReadLine());
				}
			}

			// Perform matrix addition
			int[,] sumMatrix = new int[3, 3];
			for (int i = 0; i < 3; i++)
			{
				for (int j = 0; j < 3; j++)
				{
					sumMatrix[i, j] = matrixA[i, j] + matrixB[i, j];
				}
			}

			// Transpose of Matrix A
			int[,] transposeA = new int[3, 3];
			for (int i = 0; i < 3; i++)
			{
				for (int j = 0; j < 3; j++)
				{
					transposeA[j, i] = matrixA[i, j];
				}
			}

			// Diagonal sum of Matrix A
			int diagonalSumA = 0;
			for (int i = 0; i < 3; i++)
			{
				diagonalSumA += matrixA[i, i];
			}

			// Display results
			Console.WriteLine("\nMatrix A:");
			for (int i = 0; i < 3; i++)
			{
				for (int j = 0; j < 3; j++)
				{
					Console.Write($"{matrixA[i, j]} ");
				}
				Console.WriteLine();
			}
			Console.WriteLine("\nMatrix B:");
			for (int i = 0; i < 3; i++)			
			{
				for (int j = 0; j < 3; j++)
				{
					Console.Write($"{matrixB[i, j]} ");
				}
				Console.WriteLine();
			}

			Console.WriteLine("\nSum of A and B:");
			for (int i = 0; i < 3; i++)
			{
				for (int j = 0; j < 3; j++)
				{
					Console.Write($"{sumMatrix[i, j]} ");
				}
				Console.WriteLine();
			}
			Console.WriteLine($"\nDiagonal sum of Matrix A: {diagonalSumA}");
			Console.WriteLine("\nTranspose of Matrix A:");
			for (int i = 0; i < 3; i++)
			{
				for (int j = 0; j < 3; j++)
				{
					Console.Write($"{transposeA[i, j]} ");
				}
				Console.WriteLine();
			}

			// ===============================
			// Problem 4: String Builder Challenge
			// ===============================
			// Implement text formatting tool: word count, find and replace, censor word, alternate case, slug generator, summary.

			Console.WriteLine("\nProblem 4: String Builder Challenge");
			Console.Write("Enter a paragraph: ");
			string paragraph = Console.ReadLine() ?? string.Empty;

			var sb = new StringBuilder(paragraph);

			while (true)
			{
				Console.WriteLine("\n=== TEXT TOOLS ===");
				Console.WriteLine("1. Word Count");
				Console.WriteLine("2. Find & Replace");
				Console.WriteLine("3. Censor Word");
				Console.WriteLine("4. Alternate Case");
				Console.WriteLine("5. Slug Generator");
				Console.WriteLine("6. Summary");
				Console.WriteLine("0. Exit");
				Console.Write("Choice: ");
				string choice = Console.ReadLine() ?? string.Empty;
				if (choice == "0") break;

				switch (choice)
				{
					case "1":
						var wordsArr = sb.ToString().Split(' ', StringSplitOptions.RemoveEmptyEntries);
						Console.WriteLine($"Word Count: {wordsArr.Length}");
						break;
					case "2":
						Console.Write("Find: ");
						string find = Console.ReadLine() ?? string.Empty;
						Console.Write("Replace with: ");
						string replace = Console.ReadLine() ?? string.Empty;
						if (!string.IsNullOrEmpty(find))
						{
							string result = Regex.Replace(sb.ToString(), Regex.Escape(find), replace, RegexOptions.IgnoreCase);
							sb.Clear();
							sb.Append(result);
							Console.WriteLine($"Result: \"{sb}\"");
						}
						else Console.WriteLine("Nothing to find.");
						break;
					case "3":
						Console.Write("Word to censor: ");
						string censor = Console.ReadLine() ?? string.Empty;
						if (!string.IsNullOrEmpty(censor))
						{
							string stars = new string('*', censor.Length);
							string pattern = "\\b" + Regex.Escape(censor) + "\\b";
							string res = Regex.Replace(sb.ToString(), pattern, stars, RegexOptions.IgnoreCase);
							sb.Clear();
							sb.Append(res);
							Console.WriteLine($"Result: \"{sb}\"");
						}
						else Console.WriteLine("No word entered.");
						break;
					case "4":
						var alt = new StringBuilder();
						bool makeUpper = false;
						foreach (char c in sb.ToString())
						{
							if (char.IsLetter(c))
							{
								alt.Append(makeUpper ? char.ToUpper(c) : char.ToLower(c));
								makeUpper = !makeUpper;
							}
							else alt.Append(c);
						}
						sb.Clear();
						sb.Append(alt.ToString());
						Console.WriteLine($"Result: \"{sb}\"");
						break;
					case "5":
						string slug = sb.ToString().ToLowerInvariant();
						slug = Regex.Replace(slug, @"[^a-z0-9\s-]", "");
						slug = Regex.Replace(slug, @"\s+", "-").Trim('-');
						Console.WriteLine($"Result: \"{slug}\"");
						break;
					case "6":
						Console.Write("Show first N words: ");
						if (int.TryParse(Console.ReadLine(), out int n) && n > 0)
						{
							var w = sb.ToString().Split(' ', StringSplitOptions.RemoveEmptyEntries);
							int take = Math.Min(n, w.Length);
							var sbSummary = new StringBuilder();
							for (int i = 0; i < take; i++)
							{
								if (i > 0) sbSummary.Append(' ');
								sbSummary.Append(w[i]);
							}
							if (w.Length > take) sbSummary.Append("...");
							Console.WriteLine($"Result: \"{sbSummary}\"");
						}
						else Console.WriteLine("Invalid number.");
						break;
					default:
						Console.WriteLine("Invalid choice.");
						break;
				}
			}

			// ===============================
			// Problem 5: TaskFlow Task Manager with Arrays
			// ===============================
			// Complete task manager using parallel arrays with add, view, complete, search, sort, filter, and summary features.

			Console.WriteLine("\nProblem 5: TaskFlow Task Manager with Arrays");

			const int MAX_TASKS = 20;
			string[] titles = new string[MAX_TASKS];
			string[] prioritiesArr = new string[MAX_TASKS];
			bool[] completedArr = new bool[MAX_TASKS];
			DateTime[] dueDates = new DateTime[MAX_TASKS];
			int taskCount2 = 0;

			while (true)
			{
				Console.WriteLine("\n1. Add Task    2. View All    3. Complete Task");
				Console.WriteLine("4. Search      5. Sort        6. Filter");
				Console.WriteLine("7. Summary     0. Exit");
				Console.Write("Choice: ");
				string cmd = Console.ReadLine() ?? string.Empty;
				if (cmd == "0") break;

				switch (cmd)
				{
					case "1": // Add Task
						if (taskCount2 >= MAX_TASKS) { Console.WriteLine("Task list is full (max 20)."); break; }
						Console.Write("Title: ");
						string ttitle = Console.ReadLine() ?? string.Empty;
						string prio = string.Empty;
						while (true)
						{
							Console.Write("Priority (High/Medium/Low): ");
							prio = Console.ReadLine() ?? string.Empty;
							if (prio.Equals("High", StringComparison.OrdinalIgnoreCase) ||
								prio.Equals("Medium", StringComparison.OrdinalIgnoreCase) ||
								prio.Equals("Low", StringComparison.OrdinalIgnoreCase))
							{
								prio = char.ToUpper(prio[0]) + prio.Substring(1).ToLower();
								break;
							}
							Console.WriteLine("Invalid priority. Enter High, Medium, or Low.");
						}
						DateTime due;
						while (true)
						{
							Console.Write("Due date (yyyy-MM-dd): ");
							string dInput = Console.ReadLine() ?? string.Empty;
							if (DateTime.TryParse(dInput, out due)) break;
							Console.WriteLine("Invalid date format. Try again.");
						}
						titles[taskCount2] = ttitle;
						prioritiesArr[taskCount2] = prio;
						dueDates[taskCount2] = due;
						completedArr[taskCount2] = false;
						taskCount2++;
						Console.WriteLine("Task added.");
						break;
					case "2": // View All
						if (taskCount2 == 0) { Console.WriteLine("No tasks available."); break; }
						Console.WriteLine("#   Title".PadRight(30) + "Priority".PadRight(10) + "Due Date".PadRight(15) + "Status");
						Console.WriteLine(new string('-', 70));
						for (int i = 0; i < taskCount2; i++)
						{
							string status = completedArr[i] ? "✅ Done" : "⬜ Pending";
							if (!completedArr[i] && dueDates[i] < DateTime.Today) status = "⚠️ OVERDUE";
							Console.WriteLine($"{(i + 1).ToString().PadRight(4)}{titles[i].PadRight(26)}{prioritiesArr[i].PadRight(10)}{dueDates[i].ToString("MMM dd, yyyy").PadRight(15)}{status}");
						}
						break;
					case "3": // Complete Task
						Console.Write("Enter task number to mark complete: ");
						if (int.TryParse(Console.ReadLine(), out int id) && id >= 1 && id <= taskCount2)
						{
							completedArr[id - 1] = true;
							Console.WriteLine("Marked complete.");
						}
						else Console.WriteLine("Invalid task number.");
						break;
					case "4": // Search
						Console.Write("Search keyword: ");
						string key = Console.ReadLine() ?? string.Empty;
						bool any = false;
						for (int i = 0; i < taskCount2; i++)
						{
							if (!string.IsNullOrEmpty(titles[i]) && titles[i].IndexOf(key, StringComparison.OrdinalIgnoreCase) >= 0)
							{
								if (!any)
								{
									Console.WriteLine("#   Title".PadRight(30) + "Priority".PadRight(10) + "Due Date".PadRight(15) + "Status");
									Console.WriteLine(new string('-', 70)); any = true;
								}
								string status = completedArr[i] ? "✅ Done" : "⬜ Pending";
								if (!completedArr[i] && dueDates[i] < DateTime.Today) status = "⚠️ OVERDUE";
								Console.WriteLine($"{(i + 1).ToString().PadRight(4)}{titles[i].PadRight(26)}{prioritiesArr[i].PadRight(10)}{dueDates[i].ToString("MMM dd, yyyy").PadRight(15)}{status}");
							}
						}
						if (!any) Console.WriteLine("No matching tasks found.");
						break;
					case "5": // Sort
						Console.WriteLine("Sort by: 1) Priority  2) Due Date");
						Console.Write("Choice: ");
						string sortChoice = Console.ReadLine() ?? string.Empty;
						if (sortChoice == "1")
						{
							for (int i = 0; i < taskCount2 - 1; i++)
							{
								for (int j = i + 1; j < taskCount2; j++)
								{
									int ri = MapPriority(prioritiesArr[i]), rj = MapPriority(prioritiesArr[j]);
									if (ri > rj || (ri == rj && dueDates[i] > dueDates[j]))
									{
										Swap(i, j, titles, prioritiesArr, completedArr, dueDates);
									}
								}
							}
							Console.WriteLine("Sorted by priority.");
						}
						else if (sortChoice == "2")
						{
							for (int i = 0; i < taskCount2 - 1; i++)
							{
								for (int j = i + 1; j < taskCount2; j++)
								{
									if (dueDates[i] > dueDates[j]) Swap(i, j, titles, prioritiesArr, completedArr, dueDates);
								}
							}
							Console.WriteLine("Sorted by due date.");
						}
						else Console.WriteLine("Invalid sort choice.");
						break;
					case "6": // Filter
						Console.WriteLine("Filter: 1) Pending  2) Completed  3) By Priority");
						Console.Write("Choice: ");
						string fChoice = Console.ReadLine() ?? string.Empty;
						if (fChoice == "1")
						{
							bool anyPending = false;
							for (int i = 0; i < taskCount2; i++)
							{
								if (!completedArr[i])
								{
									if (!anyPending)
									{
										Console.WriteLine("#   Title".PadRight(30) + "Priority".PadRight(10) + "Due Date".PadRight(15) + "Status");
										Console.WriteLine(new string('-', 70)); anyPending = true;
									}
									string status = !completedArr[i] && dueDates[i] < DateTime.Today ? "⚠️ OVERDUE" : "⬜ Pending";
									Console.WriteLine($"{(i + 1).ToString().PadRight(4)}{titles[i].PadRight(26)}{prioritiesArr[i].PadRight(10)}{dueDates[i].ToString("MMM dd, yyyy").PadRight(15)}{status}");
								}
							}
							if (!anyPending) Console.WriteLine("No pending tasks.");
						}
						else if (fChoice == "2")
						{
							bool anyCompleted = false;
							for (int i = 0; i < taskCount2; i++)
							{
								if (completedArr[i])
								{
									if (!anyCompleted)
									{
										Console.WriteLine("#   Title".PadRight(30) + "Priority".PadRight(10) + "Due Date".PadRight(15) + "Status");
										Console.WriteLine(new string('-', 70)); anyCompleted = true;
									}
									Console.WriteLine($"{(i + 1).ToString().PadRight(4)}{titles[i].PadRight(26)}{prioritiesArr[i].PadRight(10)}{dueDates[i].ToString("MMM dd, yyyy").PadRight(15)}{"✅ Done"}");
								}
							}
							if (!anyCompleted) Console.WriteLine("No completed tasks.");
						}
						else if (fChoice == "3")
						{
							Console.Write("Priority to filter (High/Medium/Low): ");
							string pfilter = Console.ReadLine() ?? string.Empty;
							bool anyP = false;
							for (int i = 0; i < taskCount2; i++)
							{
								if (prioritiesArr[i].Equals(pfilter, StringComparison.OrdinalIgnoreCase))
								{
									if (!anyP) { Console.WriteLine("#   Title".PadRight(30) + "Priority".PadRight(10) + "Due Date".PadRight(15) + "Status"); Console.WriteLine(new string('-', 70)); anyP = true; }
									string status = completedArr[i] ? "✅ Done" : (!completedArr[i] && dueDates[i] < DateTime.Today ? "⚠️ OVERDUE" : "⬜ Pending");
									Console.WriteLine($"{(i + 1).ToString().PadRight(4)}{titles[i].PadRight(26)}{prioritiesArr[i].PadRight(10)}{dueDates[i].ToString("MMM dd, yyyy").PadRight(15)}{status}");
								}
							}
							if (!anyP) Console.WriteLine("No tasks with that priority.");
						}
						else Console.WriteLine("Invalid filter choice.");
						break;
					case "7": // Summary
						int total = taskCount2;
						int done = 0; int overdue = 0;
						for (int i = 0; i < taskCount2; i++)
						{
							if (completedArr[i]) done++;
							else if (dueDates[i] < DateTime.Today) overdue++;
						}
						int pending = total - done;
						int percent = total == 0 ? 0 : (int)Math.Round((double)done / total * 100);
						int barSize = 20;
						int filledSize = (int)Math.Round(barSize * percent / 100.0);
						var report = new StringBuilder();
						report.AppendLine("📊 TASK SUMMARY");
						report.AppendLine(new string('-', 30));
						report.AppendLine($"Total:     {total}");
						report.AppendLine($"Completed: {done}");
						report.AppendLine($"Pending:   {pending}");
						report.AppendLine($"Overdue:   {overdue}");
						report.Append("Progress:  [");
						report.Append(new string('█', filledSize));
						report.Append(new string('░', barSize - filledSize));
						report.Append($"] {percent}%");
						Console.WriteLine(report.ToString());
						break;
					default:
						Console.WriteLine("Invalid choice.");
						break;
				}
			}

			// Local helper functions for sorting/swapping
			int MapPriority(string p)
			{
				if (string.Equals(p, "High", StringComparison.OrdinalIgnoreCase)) return 0;
				if (string.Equals(p, "Medium", StringComparison.OrdinalIgnoreCase)) return 1;
				return 2;
			}

			void Swap(int a, int b, string[] tArr, string[] pArr, bool[] cArr, DateTime[] dArr)
			{
				var tmpT = tArr[a]; tArr[a] = tArr[b]; tArr[b] = tmpT;
				var tmpP = pArr[a]; pArr[a] = pArr[b]; pArr[b] = tmpP;
				var tmpC = cArr[a]; cArr[a] = cArr[b]; cArr[b] = tmpC;
				var tmpD = dArr[a]; dArr[a] = dArr[b]; dArr[b] = tmpD;
			}

		}
	}
}
