import re
import numpy as np
import sys

# Function to parse the file and compute the stats
def process_latency_file(file_path):
    # Regular expression to match the desired lines
    final_answer_pattern = r"Final answer for\s+/(\w+) \d+/\d+: ([\d\.]+)"
    latency_pattern = r"Service Latency for /(\w+) \d+/\d+: ([\d\.]+) seconds"

    # Dictionary to store trial results by type
    trial_data = {}
    final_answers = {}

    try:
        # Open the file and process line by line
        with open(file_path, 'r') as file:
            for line in file:
                latency_match = re.search(latency_pattern, line)
                if latency_match:
                    # Extract the type and trial result (z) as a float
                    trial_type = latency_match.group(1)
                    trial_result = float(latency_match.group(2))
                    
                    if trial_type not in trial_data:
                        trial_data[trial_type] = []
                    trial_data[trial_type].append(trial_result)
                
                final_answer_match = re.search(final_answer_pattern, line)
                if final_answer_match:
                    # Extract the type and final result as a float
                    trial_type = final_answer_match.group(1)
                    final_result = int(final_answer_match.group(2))
                    
                    if trial_type in final_answers and final_answers[trial_type] != final_result:
                        print(f"Warning: Inconsistent final result for type {trial_type}!")
                    final_answers[trial_type] = final_result

        # If no results were found, handle the empty dictionary case
        if not trial_data:
            print("No matching lines were found in the file.")
            return

        # Print statistics for each type
        for trial_type, trial_results in trial_data.items():
            # Calculate statistics
            total = sum(trial_results)
            minimum = min(trial_results)
            low_quartile = np.quantile(trial_results, 0.25)
            mid_quartile = np.quantile(trial_results, 0.5)
            high_quartile = np.quantile(trial_results, 0.75)
            maximum = max(trial_results)
            average = total / len(trial_results)
            req_fulfilled = len(trial_results)

            
            print(f"Statistics for type: {trial_type}")
            #print(f"  Minimum trial result: {minimum:.2f} seconds")
            #print(f"  Maximum trial result: {maximum:.2f} seconds")
            #print(f"  Total of all trial results: {total:.2f} seconds")
            #print(f"  Average trial result: {average:.2f} seconds")
            #print(f"  {trial_type} min latency: {int(minimum)} seconds")
            #print(f"  {trial_type} max latency: {int(maximum)} seconds")
            #print(f"  {trial_type} Total of all trial results: {int(total)} seconds")
            #print(f"  {trial_type} Average trial result: {int(average)} seconds")

            print(f"  {trial_type} min latency: {minimum:.6f} seconds")
            print(f"  {trial_type} low latency: {low_quartile:.6f} seconds")
            print(f"  {trial_type} mid latency: {mid_quartile:.6f} seconds")
            print(f"  {trial_type} high latency: {high_quartile:.6f} seconds")
            print(f"  {trial_type} max latency: {maximum:.6f} seconds")
            print(f"  {trial_type} total latency: {total:.6f} seconds")
            print(f"  {trial_type} avg latency: {average:.6f} seconds")
            print(f"  {trial_type} requests fulfilled: {int(req_fulfilled)} total requests")
            
            if trial_type in final_answers:
                #print(f"  Final answer: {final_answers[trial_type]:.2f} seconds")
                print(f"  {trial_type} Final answer: {int(final_answers[trial_type])} numerical")
            print()

    except FileNotFoundError:
        print(f"Error: The file '{file_path}' was not found.")
    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage
if __name__ == "__main__":
    print("Processing intervals log file!")
    #file_path = "/tmp/minindn/user/cabeee_consumer.log"
    file_path = sys.argv[1]
    process_latency_file(file_path)
