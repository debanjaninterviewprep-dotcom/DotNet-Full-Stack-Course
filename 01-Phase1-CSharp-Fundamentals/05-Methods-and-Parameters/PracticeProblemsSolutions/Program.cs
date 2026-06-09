using System;
using System.Linq;
using System.Collections.Generic;

namespace PracticeProblemsSolutions
{
	class Program
	{
		static void Main(string[] args)
		{
			// ===============================
			// Problem 1: Method Toolbox
			// ===============================
			// Create utility methods: PrintSeparator, Reverse string, Max of two numbers, IsPalindrome checker using expression-bodied methods.

			Console.WriteLine("=== Problem 1: Method Toolbox ===");
			
			static void PrintSeparator() => Console.WriteLine(new string('-', 40));
			static string Reverse(string input) => new string(input.ToCharArray().Reverse().ToArray());
			static int Max(int a, int b) => a > b ? a : b;
			static bool IsPalindrome(string input) => input.Equals(Reverse(input), StringComparison.OrdinalIgnoreCase);

			// Test the utility methods

			 PrintSeparator();
			string testString = "racecar";
			Console.WriteLine($"Original: {testString}");
			Console.WriteLine($"Reversed: {Reverse(testString)}");
			Console.WriteLine($"Is Palindrome: {IsPalindrome(testString)}");
			Console.WriteLine($"Max of 5 and 10: {Max(5, 10)}");
			 PrintSeparator();

			// ===============================
			// Problem 2: Overloaded Calculator
			// ===============================
			// Implement 4 overloaded Calculate methods: two ints, two doubles, with operation string, with params array.

			Console.WriteLine("=== Problem 2: Overloaded Calculator ===");

			// Calculator helpers are implemented as class-level overloads below.

			 // Test the overloaded methods
			Console.WriteLine($"Calculate(3, 4): {Calculate(3, 4)}");
			Console.WriteLine($"Calculate(3.5, 4.5): {Calculate(3.5, 4.5)}");
			Console.WriteLine($"Calculate(10.0, 5.0, \"+\"): {Calculate(10.0, 5.0, "+")}");
			Console.WriteLine($"Calculate(1.0, 2.0, 3.0): {Calculate(1.0, 2.0, 3.0)}");
			 PrintSeparator();


			// ===============================
			// Problem 3: ref/out Swap & Split
			// ===============================
			// Implement Swap using ref, MinMax using out, and TryParseFullName splitting first and last name using out parameters.

			Console.WriteLine("=== Problem 3: ref/out Swap & Split ===");

			static void Swap(ref int a, ref int b)
			{
				int temp = a;
				a = b;
				b = temp;
			}

			static void MinMax(int a, int b, out int min, out int max)
			{
				min = a < b ? a : b;
				max = a > b ? a : b;
			}

			static bool TryParseFullName(string fullName, out string? firstName, out string? lastName)
			{
				var parts = fullName.Split(' ');
				if (parts.Length == 2)
				{
					firstName = parts[0];
					lastName = parts[1];
					return true;
				}
				firstName = null;
				lastName = null;
				return false;
			}

			 // Test the ref/out methods
			int x = 5, y = 10;
			Console.WriteLine($"Before Swap: x={x}, y={y}");
			Swap(ref x, ref y);
			Console.WriteLine($"After Swap: x={x}, y={y}");
			int min, max;
			MinMax(3, 7, out min, out max);
			Console.WriteLine($"Min: {min}, Max: {max}");
			string? firstName, lastName;
			if (TryParseFullName("John Doe", out firstName, out lastName))
			{
				Console.WriteLine($"First Name: {firstName}, Last Name: {lastName}");
			}
			 PrintSeparator();


			// ===============================
			// Problem 4: Recursive Power Calculator
			// ===============================
			// Calculate base^exponent recursively, sum of digits, and count digits in number with base cases.

			Console.WriteLine("=== Problem 4: Recursive Power Calculator ===");
			static double Power(double baseNum, int exponent)
			{
				if (exponent == 0) return 1;
				if (exponent < 0) return 1 / Power(baseNum, -exponent);
				return baseNum * Power(baseNum, exponent - 1);
			}
			 PrintSeparator();
			
			static int SumOfDigits(int number)
			{
				if (number == 0) return 0;
				return (number % 10) + SumOfDigits(number / 10);
			}
			 PrintSeparator();
			
			static int CountDigits(int number)
			{
				if (number == 0) return 0;
				return 1 + CountDigits(number / 10);
			}
			 PrintSeparator();

			 // Test the recursive methods
			Console.WriteLine($"Power(2, 3): {Power(2, 3)}");
			Console.WriteLine($"SumOfDigits(12345): {SumOfDigits(12345)}");
			Console.WriteLine($"CountDigits(12345): {CountDigits(12345)}");
			 PrintSeparator();


			// ===============================
			// Problem 5: TaskFlow Command System
			// ===============================
			Console.WriteLine("=== Problem 5: TaskFlow Command System ===");

			var tasks = new List<TaskItem>();

			bool exitTaskFlow = false;
			while (!exitTaskFlow)
			{
				PrintSeparator();
				Console.WriteLine("TaskFlow - choose an option:");
				Console.WriteLine("1) Add Task");
				Console.WriteLine("2) View Tasks");
				Console.WriteLine("3) Statistics");
				Console.WriteLine("4) Complete Task");
				Console.WriteLine("5) Exit TaskFlow");
				Console.Write("Choice: ");
				var choice = Console.ReadLine()?.Trim();

				switch (choice)
				{
					case "1":
						AddTaskInteractive(tasks);
						break;
					case "2":
						ViewTasksInteractive(tasks);
						break;
					case "3":
						var stats = GetStatistics(tasks);
						Console.WriteLine($"Total: {stats.total}, Completed: {stats.completed}, Pending: {stats.pending}");
						break;
					case "4":
						CompleteTaskInteractive(tasks);
						break;
					case "5":
						exitTaskFlow = true;
						break;
					default:
						Console.WriteLine("Invalid choice.");
						break;
				}
			}

			PrintSeparator();
			Console.WriteLine("=== End of Practice Problems ===");
			PrintSeparator();

			// Local interactive helpers
			void AddTaskInteractive(List<TaskItem> list)
			{
				Console.Write("Title: ");
				var title = Console.ReadLine()?.Trim();
				if (string.IsNullOrEmpty(title)) { Console.WriteLine("Title is required."); return; }
				Console.Write("Description (optional): ");
				var desc = Console.ReadLine();
				Console.Write("Priority (1-5, default 1): ");
				var prInput = Console.ReadLine();
				int priority = 1;
				if (!string.IsNullOrWhiteSpace(prInput) && !int.TryParse(prInput, out priority)) priority = 1;
				Console.Write("Due date (yyyy-MM-dd, optional): ");
				var dueInput = Console.ReadLine();
				DateTime? due = null;
				if (!string.IsNullOrWhiteSpace(dueInput) && DateTime.TryParse(dueInput, out var d)) due = d;
				AddTask(list, title, desc, priority, due);
				Console.WriteLine("Task added.");
			}

			void ViewTasksInteractive(List<TaskItem> list)
			{
				Console.WriteLine("Filter: (a)ll / (p)ending / (c)ompleted / (r) priority >= N / (d)ue before date");
				Console.Write("Choice: ");
				var f = Console.ReadLine()?.Trim().ToLower();
				IEnumerable<TaskItem> results = list;
				switch (f)
				{
					case "a":
						results = ViewTasks(list);
						break;
					case "p":
						results = ViewTasks(list, t => !t.Completed);
						break;
					case "c":
						results = ViewTasks(list, t => t.Completed);
						break;
					case "r":
						Console.Write("Min priority: ");
						if (int.TryParse(Console.ReadLine(), out var minPr))
							results = ViewTasks(list, t => t.Priority >= minPr);
						else { Console.WriteLine("Invalid priority."); return; }
						break;
					case "d":
						Console.Write("Before date (yyyy-MM-dd): ");
						if (DateTime.TryParse(Console.ReadLine(), out var before))
							results = ViewTasks(list, t => t.Due.HasValue && t.Due.Value.Date <= before.Date);
						else { Console.WriteLine("Invalid date."); return; }
						break;
					default:
						Console.WriteLine("Invalid filter.");
						return;
				}

				PrintSeparator();
				foreach (var ti in results)
					Console.WriteLine(ti);
				PrintSeparator();
			}

			void CompleteTaskInteractive(List<TaskItem> list)
			{
				if (!list.Any()) { Console.WriteLine("No tasks available."); return; }
				Console.Write("Enter task id to complete: ");
				if (!int.TryParse(Console.ReadLine(), out var id)) { Console.WriteLine("Invalid id."); return; }
				var idx = list.FindIndex(t => t.Id == id);
				if (idx == -1) { Console.WriteLine("Task not found."); return; }
				var tmp = list[idx];
				CompleteTask(ref tmp);
				list[idx] = tmp;
				Console.WriteLine("Task marked complete.");
			}

		}

		// Class-level overloaded Calculate methods
		static int Calculate(int a, int b) => a + b;
		static double Calculate(double a, double b) => a + b;
		static double Calculate(double a, double b, string operation)
		{
			return operation switch
			{
				"+" => a + b,
				"-" => a - b,
				"*" => a * b,
				"/" => b != 0 ? a / b : throw new DivideByZeroException(),
				_ => throw new ArgumentException("Invalid operation")
			};
		}
		static double Calculate(params double[] numbers) => numbers.Sum();

		// TaskFlow implementation for Problem 5
		struct TaskItem
		{
			private static int _nextId;
			public int Id { get; init; }
			public string Title { get; set; }
			public string Description { get; set; }
			public int Priority { get; set; }
			public DateTime? Due { get; set; }
			public bool Completed { get; set; }

			public TaskItem(string title, string? description = null, int priority = 1, DateTime? due = null)
			{
				Id = ++_nextId;
				Title = title;
				Description = description ?? string.Empty;
				Priority = priority;
				Due = due;
				Completed = false;
			}

			public override string ToString()
			{
				var status = Completed ? "X" : " ";
				var dueStr = Due.HasValue ? $" Due:{Due.Value:d}" : string.Empty;
				var desc = string.IsNullOrEmpty(Description) ? string.Empty : $" - {Description}";
				return $"{Id}. [{status}] {Title} (Priority:{Priority}){dueStr}{desc}";
			}
		}

		static void AddTask(List<TaskItem> tasks, string title, string? description = null, int priority = 1, DateTime? due = null)
			=> tasks.Add(new TaskItem(title, description, priority, due));

		static IEnumerable<TaskItem> ViewTasks(List<TaskItem> tasks, params Func<TaskItem, bool>[] filters)
		{
			IEnumerable<TaskItem> q = tasks;
			if (filters != null && filters.Length > 0)
				q = q.Where(t => filters.All(f => f(t)));
			return q;
		}

		static (int total, int completed, int pending) GetStatistics(IEnumerable<TaskItem> tasks)
		{
			var total = tasks.Count();
			var completed = tasks.Count(t => t.Completed);
			return (total, completed, total - completed);
		}

		static void CompleteTask(ref TaskItem task) => task.Completed = true;
	}
}
