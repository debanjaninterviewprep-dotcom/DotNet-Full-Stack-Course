using System;

namespace PracticeProblemsSolutions
{
	class Program
	{
		static void Main(string[] args)
		{
			// ===============================
			// Problem 1: Abstract Shape System
			// ===============================
			// Abstract Shape class with abstract Area/Perimeter, concrete Rectangle/Circle/Triangle, Describe method using polymorphism.

			Console.WriteLine("=== Problem 1: Abstract Shape System ===");

			Shape[] shapes = new Shape[]
			{
				new Rectangle { Width = 4, Height = 5 },
				new Circle { Radius = 3 },
				new Triangle { SideA = 3, SideB = 4, SideC = 5 }
			};

			foreach (var shape in shapes)
			{
				shape.Describe();
			}


			// ===============================
			// Problem 2: Interface-Based Logger
			// ===============================
			// ILogger interface with Log/LogError/LogWarning, implement ConsoleLogger/FileLogger/MemoryLogger, demonstrate polymorphism.

			Console.WriteLine("\n=== Problem 2: Interface-Based Logger ===\n");

			ILogger[] loggers = new ILogger[]
			{
				new ConsoleLogger(),
				new FileLogger($"C:\\Debanjan's Data\\VS Code\\DotNet-Full-Stack-Course\\01-Phase1-CSharp-Fundamentals\\09-OOP-Abstraction-and-Interfaces\\PracticeProblemsSolutions\\Logs\\log_{DateTime.Now:yyyyMMdd_HHmm}.txt"),
				new MemoryLogger()
			};

			foreach (var logger in loggers)
			{
				logger.Log("This is an info message.");
				logger.LogWarning("This is a warning message.");
				logger.LogError("This is an error message.");

				if (logger is MemoryLogger memoryLogger)
				{
					Console.WriteLine("Memory Logger Contents:");
					memoryLogger.PrintLogs();
				}
				else if (logger is FileLogger)
				{
					Console.WriteLine($"Logged to file: log_{DateTime.Now:yyyyMMdd_HHmm}.txt");
				}
			}

			// ===============================
			// Problem 3: Interface Segregation - Document System
			// ===============================
			// Small focused interfaces (IPrintable, IScannable, IFaxable, IEmailable), classes implement only needed ones.

			Console.WriteLine("\n=== Problem 3: Interface Segregation - Document System ===\n");

			IPrintable[] printers = new IPrintable[]
			{
				new MultiFunctionPrinter(),
				new SimplePrinter(),
				new DigitalDocument()
			};

			foreach (var printer in printers)
			{
				printer.Print();
			}




			// ===============================
			// Problem 4: Sortable & Equatable Task System
			// ===============================
			// TaskItem implementing IComparable, IEquatable, IFormattable for sorting by priority and custom format strings.

			Console.WriteLine("\n=== Problem 4: Sortable & Equatable Task System ===\n");

			TaskItem[] tasks = new TaskItem[]
			{
				new TaskItem { Id = 1, Title = "Buy groceries", Priority = "High" },
				new TaskItem { Id = 2, Title = "Clean the house", Priority = "Medium" },
				new TaskItem { Id = 3, Title = "Pay bills", Priority = "Low" },
				new TaskItem { Id = 4, Title = "Finish project", Priority = "High" }
			};

			tasks.Sort();

			tasks[2].Equals(tasks[3]);
			tasks[0].Equals(tasks[3]);

			foreach (var task in tasks)
			{
				Console.WriteLine(task.ToString("G", null));
			}

			foreach (var task in tasks)
			{
				Console.WriteLine(task.ToString("D", null));
			}

			// ===============================
			// Problem 5: TaskFlow Service Layer
			// ===============================
			// Generic IRepository<T>, INotificationService, IExportService interfaces with concrete implementations, dependency inversion.

			Console.WriteLine("\n=== Problem 5: TaskFlow Service Layer ===\n");


			IRepository<TaskBase_Five> repo = new InMemoryTaskRepository();
			INotificationService notifier = new ConsoleNotificationService();
			IExportService<TaskBase_Five> exporter = new SimpleExportService<TaskBase_Five>();

			int idCounter = 1;

			while (true)
			{
				Console.WriteLine("\n1. Add Task\n2. View Tasks\n3. Export\n4. Complete Task\n5. Stats\n0. Exit");
				var choice = Console.ReadLine();

				if (choice == "1")
				{
					Console.WriteLine("Choose Type: 1-Bug 2-Feature 3-Chore");
					var type = Console.ReadLine();

					Console.Write("Title: ");
					var title = Console.ReadLine();

					TaskBase_Five task = type switch
					{
						"1" => new BugTask(),
						"2" => new FeatureTask(),
						_ => new ChoreTask()
					};

					task.Id = idCounter++;
					task.Title = title;

					repo.Add(task);

					notifier.Send("user@taskflow.com", "Task Created", $"Task '{task.Title}' added");
				}

				else if (choice == "2")
				{
					var taskss = repo.GetAll();
					taskss.Sort();

					foreach (var t in taskss)
					{
						Console.WriteLine($"{t.Id} | {t.Title} | {t.GetCategory()} | Priority: {t.GetPriorityScore()} | Done: {t.IsCompleted}");
					}
				}

				else if (choice == "3")
				{
					var taskss = repo.GetAll();
					Console.WriteLine("1-CSV 2-JSON");
					var opt = Console.ReadLine();

					if (opt == "1")
						Console.WriteLine(exporter.ExportToCsv(taskss));
					else
						Console.WriteLine(exporter.ExportToJson(taskss));
				}

				else if (choice == "4")
				{
					Console.Write("Enter Task ID: ");
					int id = int.Parse(Console.ReadLine());

					var task = repo.GetById(id);
					if (task != null)
					{
						task.IsCompleted = true;
						notifier.Send("user@taskflow.com", "Task Completed", $"Task '{task.Title}' completed");
					}
				}

				else if (choice == "5")
				{
					var taskss = repo.GetAll();

					Console.WriteLine($"Total Tasks: {repo.Count}");
					Console.WriteLine($"Completed: {taskss.Count(t => t.IsCompleted)}");
					Console.WriteLine($"Pending: {taskss.Count(t => !t.IsCompleted)}");
				}

				else if (choice == "0") break;
			}


		}
	}
}
