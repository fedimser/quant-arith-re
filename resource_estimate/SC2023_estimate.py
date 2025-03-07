import qsharp
import random, json

qsharp.init(project_root="./lib/")

op = "QuantumArithmetic.SC2023.Add"
results = []
for n in [2, 3, 4, 5, 8, 9, 16, 17, 32, 33]:
    x, y = random.randint(0, 2**n-1), random.randint(0, 2**n-1)
    results.append (qsharp.estimate(f"EstimateUtils.BinaryOpExtraOut({n},{x},{y},{op})", 
                    params={"qubitParams": {
                        "name": "qubit_maj_ns_e6"
                    },
                }))
        
with open("resource_estimate/results/SC2023_Add_estimate.json", "w") as f:
    json.dump(results, f, indent=4)
    
# result_obj = json.loads(result.json)
# if isinstance(result_obj, dict):
#     result_obj = [result_obj]

# data = []
# for item in result_obj:
#     data_item = []

#     # Run name
#     data_item.append(item["jobParams"]["qubitParams"]["name"])

#     # T factory fraction and Runtime
#     if "physicalCountsFormatted" in item:
#         data_item.append(
#             item["physicalCountsFormatted"]["physicalQubitsForTfactoriesPercentage"]
#         )
#         data_item.append(item["physicalCountsFormatted"]["runtime"])
#     elif "frontierEntries" in item:
#         data_item.append(
#             item["frontierEntries"][0]["physicalCountsFormatted"][
#                 "physicalQubitsForTfactoriesPercentage"
#             ]
#         )
#         data_item.append(
#             item["frontierEntries"][0]["physicalCountsFormatted"]["runtime"]
#         )
#     else:
#         data_item.append("-")
#         data_item.append("-")

#     # Physical qubits and rQOPS
#     if "physicalCounts" in item:
#         data_item.append(item["physicalCounts"]["physicalQubits"])
#         data_item.append(item["physicalCounts"]["rqops"])
#     elif "frontierEntries" in item:
#         data_item.append(item["frontierEntries"][0]["physicalCounts"]["physicalQubits"])
#         data_item.append(item["frontierEntries"][0]["physicalCounts"]["rqops"])
#     else:
#         data_item.append("-")
#         data_item.append("-")

#     data.append(data_item)

# # Define the table headers
# headers = ["Run name", "T factory fraction", "Runtime", "Physical qubits", "rQOPS"]

# # Determine the width of each column
# col_widths = [max(len(str(item)) for item in column) for column in zip(headers, *data)]


# # Function to format a row
# def format_row(row):
#     return " | ".join(
#         f"{str(item).ljust(width)}" for item, width in zip(row, col_widths)
#     )


# # Create the table
# header_row = format_row(headers)
# separator_row = "-+-".join("-" * width for width in col_widths)
# data_rows = [format_row(row) for row in data]

# # Print the table
# print(header_row)
# print(separator_row)
# for row in data_rows:
#     print(row)