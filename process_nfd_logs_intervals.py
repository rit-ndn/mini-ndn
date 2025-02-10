import re
import numpy as np

# Function to parse the file and compute the stats
def process_latency_file(file_path):
    # Regular expression to match the desired lines
    pattern = r"Service Latency \d+/\d+: ([\d\.]+) seconds"

    # List to store all extracted trial results
    trial_results = []

    try:
        # Open the file and process line by line
        with open(file_path, 'r') as file:
            for line in file:
                match = re.search(pattern, line)
                if match:
                    # Extract the trial result (z)
                    trial_result = float(match.group(1))
                    trial_results.append(trial_result)

        # If no results were found, handle the empty list case
        if not trial_results:
            print("No matching lines were found in the file.")
            return

        # Calculate statistics
        total = sum(trial_results)
        minimum = min(trial_results)
        low_quartile = np.quantile(trial_results, 0.25)
        mid_quartile = np.quantile(trial_results, 0.5)
        high_quartile = np.quantile(trial_results, 0.75)
        maximum = max(trial_results)
        average = total / len(trial_results)

        # Print the results
        print("")
        print(f"min latency: {minimum} seconds")
        print(f"low latency: {low_quartile} seconds")
        print(f"mid latency: {mid_quartile} seconds")
        print(f"high latency: {high_quartile} seconds")
        print(f"max latency: {maximum} seconds")
        print(f"total latency: {total} seconds")
        print(f"avg latency: {average} seconds")
        print("")

    except FileNotFoundError:
        print(f"Error: The file '{file_path}' was not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage
if __name__ == "__main__":
    print("Processing intervals log file!")
    file_path = "/tmp/minindn/user/cabeee_consumer.log"
    process_latency_file(file_path)
