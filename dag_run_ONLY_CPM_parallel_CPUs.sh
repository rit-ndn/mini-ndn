#!/bin/bash
# vim: sw=8 noet

set -e

# --- 1. Check Input Arguments ---
if [ -z "$1" ]; then
    echo "Usage: $0 <path_to_csv_file>"
    exit 1
fi

export csv_out="$1"

if [ ! -f "$csv_out" ]; then
    echo "Error: Could not find CSV file at $csv_out"
    exit 1
fi

# --- 2. Define Directories ---
export MININDN_HOME="$HOME/mini-ndn"
export WORKFLOW_DIR="$MININDN_HOME/workflows"
export TOPOLOGY_DIR="$MININDN_HOME/topologies"
export CPM_DIR="$HOME/CPM"

# --- 3. Define Scenarios ---
declare -a scenarios=(
# 4 DAG
"cabeee-4dag-orchestratorA.py orchA 4dag.json 4dag.hosting cabeee-3node.json"
"cabeee-4dag-orchestratorB.py orchB 4dag.json 4dag.hosting cabeee-3node.json"
"cabeee-4dag-nesco.py nesco 4dag.json 4dag.hosting cabeee-3node.json"
"cabeee-4dag-nescoSCOPT.py nescoSCOPT 4dag.json 4dag.hosting cabeee-3node.json"
# 8 DAG
"cabeee-8dag-orchestratorA.py orchA 8dag.json 8dag.hosting cabeee-3node.json"
"cabeee-8dag-orchestratorB.py orchB 8dag.json 8dag.hosting cabeee-3node.json"
"cabeee-8dag-nesco.py nesco 8dag.json 8dag.hosting cabeee-3node.json"
"cabeee-8dag-nescoSCOPT.py nescoSCOPT 8dag.json 8dag.hosting cabeee-3node.json"
# 8 DAG w/ caching
"cabeee-8dag-caching-orchestratorA.py orchA 8dag.json 8dag.hosting cabeee-3node.json"
"cabeee-8dag-caching-orchestratorB.py orchB 8dag.json 8dag.hosting cabeee-3node.json"
"cabeee-8dag-caching-nesco.py nesco 8dag.json 8dag.hosting cabeee-3node.json"
"cabeee-8dag-caching-nescoSCOPT.py nescoSCOPT 8dag.json 8dag.hosting cabeee-3node.json"
# 20 Sensor (using 3node topology)
"cabeee-20sensor-orchestratorA.py orchA 20-sensor.json 20-sensor-in3node.hosting cabeee-3node.json"
"cabeee-20sensor-orchestratorB.py orchB 20-sensor.json 20-sensor-in3node.hosting cabeee-3node.json"
"cabeee-20sensor-nesco.py nesco 20-sensor.json 20-sensor-in3node.hosting cabeee-3node.json"
"cabeee-20sensor-nescoSCOPT.py nescoSCOPT 20-sensor.json 20-sensor-in3node.hosting cabeee-3node.json"
# 20 Linear (using 3node topology)
"cabeee-20linear-orchestratorA.py orchA 20-linear.json 20-linear-in3node.hosting cabeee-3node.json"
"cabeee-20linear-orchestratorB.py orchB 20-linear.json 20-linear-in3node.hosting cabeee-3node.json"
"cabeee-20linear-nesco.py nesco 20-linear.json 20-linear-in3node.hosting cabeee-3node.json"
"cabeee-20linear-nescoSCOPT.py nescoSCOPT 20-linear.json 20-linear-in3node.hosting cabeee-3node.json"
# 20 Reuse (using 3node topology)
"cabeee-20reuse-orchestratorA.py orchA 20-reuse.json 20-reuse-in3node.hosting cabeee-3node.json"
"cabeee-20reuse-orchestratorB.py orchB 20-reuse.json 20-reuse-in3node.hosting cabeee-3node.json"
"cabeee-20reuse-nesco.py nesco 20-reuse.json 20-reuse-in3node.hosting cabeee-3node.json"
"cabeee-20reuse-nescoSCOPT.py nescoSCOPT 20-reuse.json 20-reuse-in3node.hosting cabeee-3node.json"
# Category 01 (multi-tiered_linear)
"cabeee-cat01-mt_linear-orchestratorA.py orchA cat01-linear.json cat01-mt-linear.hosting cabeee-cat01-multi_tier.json"
"cabeee-cat01-mt_linear-orchestratorB.py orchB cat01-linear.json cat01-mt-linear.hosting cabeee-cat01-multi_tier.json"
"cabeee-cat01-mt_linear-nesco.py nesco cat01-linear.json cat01-mt-linear.hosting cabeee-cat01-multi_tier.json"
"cabeee-cat01-mt_linear-nescoSCOPT.py nescoSCOPT cat01-linear.json cat01-mt-linear.hosting cabeee-cat01-multi_tier.json"
# Category 02 (star-of-stars_map-reduce)
"cabeee-cat02-sos_mr-orchestratorA.py orchA cat02-map_reduce.json cat02-sos-map_reduce.hosting cabeee-cat02-star_of_stars.json"
"cabeee-cat02-sos_mr-orchestratorB.py orchB cat02-map_reduce.json cat02-sos-map_reduce.hosting cabeee-cat02-star_of_stars.json"
"cabeee-cat02-sos_mr-nesco.py nesco cat02-map_reduce.json cat02-sos-map_reduce.hosting cabeee-cat02-star_of_stars.json"
"cabeee-cat02-sos_mr-nescoSCOPT.py nescoSCOPT cat02-map_reduce.json cat02-sos-map_reduce.hosting cabeee-cat02-star_of_stars.json"
# Category 03 (mesh_map-reduce)
"cabeee-cat03-mesh_mr-orchestratorA.py orchA cat03-map_reduce.json cat03-mesh-map_reduce.hosting cabeee-cat03-mesh.json"
"cabeee-cat03-mesh_mr-orchestratorB.py orchB cat03-map_reduce.json cat03-mesh-map_reduce.hosting cabeee-cat03-mesh.json"
"cabeee-cat03-mesh_mr-nesco.py nesco cat03-map_reduce.json cat03-mesh-map_reduce.hosting cabeee-cat03-mesh.json"
"cabeee-cat03-mesh_mr-nescoSCOPT.py nescoSCOPT cat03-map_reduce.json cat03-mesh-map_reduce.hosting cabeee-cat03-mesh.json"
# Category 04 (mesh_wavefront)
"cabeee-cat04-mesh_wf-orchestratorA.py orchA cat04-wavefront.json cat04-mesh-wavefront.hosting cabeee-cat04-mesh.json"
"cabeee-cat04-mesh_wf-orchestratorB.py orchB cat04-wavefront.json cat04-mesh-wavefront.hosting cabeee-cat04-mesh.json"
"cabeee-cat04-mesh_wf-nesco.py nesco cat04-wavefront.json cat04-mesh-wavefront.hosting cabeee-cat04-mesh.json"
"cabeee-cat04-mesh_wf-nescoSCOPT.py nescoSCOPT cat04-wavefront.json cat04-mesh-wavefront.hosting cabeee-cat04-mesh.json"
)

# --- 4. Dynamic Column Detection ---
export COL_CPM=$(head -n 1 "$csv_out" | awk -F',' '{for(i=1;i<=NF;i++) if($i ~ /Critical-Path-Metric|CPM/ && $i !~ /CPM-t_exec/) print i}')
export COL_TIME=$(head -n 1 "$csv_out" | awk -F',' '{for(i=1;i<=NF;i++) if($i ~ /CPM-t_exec/) print i}')

if [ -z "$COL_CPM" ] || [ -z "$COL_TIME" ]; then
    echo "Error: Could not find both CPM and CPM-t_exec(ns) columns in the header."
    exit 1
fi

echo "Found CPM column at index: $COL_CPM"
echo "Found CPM-t_exec(ns) column at index: $COL_TIME"

# --- 5. Backup ---
echo "Backing up original CSV to ${csv_out}.backup_before_emulation_cpm..."
cp "$csv_out" "${csv_out}.backup_before_emulation_cpm"

# --- 6. Define the Worker Function ---
update_cpm_emulation() {
    local iterator="$1"
    
    # Parse the scenario string array
    read -a itrArray <<< "$iterator"
    local script="${itrArray[0]}"
    local type="${itrArray[1]}"
    local wf="${WORKFLOW_DIR}/${itrArray[2]}"
    local hosting="${WORKFLOW_DIR}/${itrArray[3]}"
    local topo="${TOPOLOGY_DIR}/${itrArray[4]}"

    # Find ALL line numbers in the CSV that match this script
    # We use "^\s*${script}," to ensure it only matches the first column precisely
    local line_nums=$(grep -n -E "^\s*${script}," "$csv_out" | cut -d: -f1)

    if [ -z "$line_nums" ]; then
        echo "Warning: Scenario $script not found in CSV. Skipping."
        return
    fi

    local updated_count=0

    # Iterate over every found line (e.g., all 20 samples)
    for line_num in $line_nums; do
        # Run the CPM tool natively
        set +e
        local cpm_output=$("${CPM_DIR}/cpm" --scheme "$type" --workflow "$wf" --hosting "$hosting" --topology "$topo" 2>&1)
        local cpm_status=$?
        set -e

        local cpm cpm_t
        if  [ $cpm_status -ne 0 ]; then
            echo "Warning: CPM failed with exit code $cpm_status on scenario $script"
            cpm=""
            cpm_t=""
        else
            cpm=$(echo "$cpm_output" | sed -n 's/^metric: \([0-9]*\)/\1/p' | tr -d '\n')
            cpm_t=$(echo "$cpm_output" | sed -n 's/^time: \([0-9]*\) ns/\1/p' | tr -d '\n')
        fi

        # Lock the CSV file and precisely update this specific line
        (
            flock -x 200
            
            local current_line=$(sed -n "${line_num}p" "$csv_out")
            local new_line=$(echo "$current_line" | awk -F',' -v OFS=',' -v c="$cpm" -v ct="$cpm_t" -v col_cpm="$COL_CPM" -v col_time="$COL_TIME" '{ $col_cpm=" "c; $col_time=" "ct; print }')
            
            sed --in-place -e "${line_num}c\\$new_line" "$csv_out"
        ) 200> "${csv_out}.lock"

        # FIXED: Avoid set -e trap by using a safe assignment instead of (( ++ ))
        updated_count=$((updated_count + 1))
    done

    echo "Updated $updated_count sample(s) for $script"
}
export -f update_cpm_emulation

# --- 7. Dispatch Jobs ---
echo "Dispatching emulation CPM updates..."

# Pipe the scenario definitions directly into parallel
# FIXED: Placed "{}" in quotes so the full array string isn't split
printf "%s\n" "${scenarios[@]}" | parallel --jobs 0 update_cpm_emulation "{}"

echo "All emulation CPM updates completed at $(date '+%H:%M:%S')."