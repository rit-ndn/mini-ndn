# -*- Mode:python; c-file-style:"gnu"; indent-tabs-mode:nil -*- */
#
# Copyright (C) 2015-2020, The University of Memphis,
#                          Arizona Board of Regents,
#                          Regents of the University of California.
#
# This file is part of Mini-NDN.
# See AUTHORS.md for a complete list of Mini-NDN authors and contributors.
#
# Mini-NDN is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Mini-NDN is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Mini-NDN, e.g., in COPYING.md file.
# If not, see <http://www.gnu.org/licenses/>.


from mininet.log import setLogLevel, info
import os

class MergeNFDLogs(object):
    """This will contain methods to merge NFD logs

     Usage from Experiment folder: `not sure yet...`
    """

    #@staticmethod
    def deleteAllLogs():
        """This will delete all the logs found in /tmp/minindn/

        """

        info("Deleting all logs!\n")

        directory_path = '/tmp/minindn'
        output_file_path = 'mergedLog.log'
        target_filename = 'nfd.log'

        try:
            os.remove(output_file_path)
            print(f"Deleted: {output_file_path}")
        except Exception as e:
            print(f"Error deleting {output_file_path}: {e}")

        for root, dirs, files in os.walk(directory_path):
            for file in files:
                if file == target_filename:
                    file_path = os.path.join(root, file)
                    try:
                        os.remove(file_path)
                        print(f"Deleted: {file_path}")
                    except Exception as e:
                        print(f"Error deleting {file_path}: {e}")

        return None

    

    @staticmethod
    def get_first_folder_name(file_path, base_directory):
        relative_path = os.path.relpath(file_path, base_directory)
        first_folder = os.path.dirname(relative_path).split(os.sep)[0]
        return first_folder

    @staticmethod
    def read_lines_from_directory(directory_path, target_filename):
        lines = []
        # Walk through the directory
        for root, _, files in os.walk(directory_path):
            for file_name in files:
                if file_name == target_filename:
                    file_path = os.path.join(root, file_name)
                    # Check if it is a file (not a directory)
                    if os.path.isfile(file_path):
                        first_folder = MergeNFDLogs.get_first_folder_name(file_path, directory_path)
                        with open(file_path, 'r', encoding='utf-8') as file:
                            #lines.extend(file.readlines())
                            #lines.extend(line for line in file if line.strip()) # skip empty lines
                            for line in file:
                                if line.strip():
                                    # Insert the filename after the first space
                                    parts = line.split(' ', 1)
                                    if len(parts) > 1:
                                        line_with_filename = f"{parts[0]} [{first_folder}] {parts[1]}"
                                    else:
                                        line_with_filename = f"{parts[0]} [{first_folder}]"
                                    lines.append(line_with_filename)
        return lines

    @staticmethod
    def write_sorted_lines_to_file(lines, output_file_path):
        # Sort lines alphabetically
        sorted_lines = sorted(lines)
        # Write the sorted lines to the output file
        with open(output_file_path, 'w', encoding='utf-8') as output_file:
            output_file.writelines(sorted_lines)

    @staticmethod
    def count_specific_lines(output_file_path, keyword1, keyword2):
        count = 0
        with open(output_file_path, 'r', encoding='utf-8') as file:
            for line in file:
                if keyword1 in line and keyword2 in line:
                    count += 1
                if "serviceOrchestration/reset" in line:
                    count = 0
        return count

    #@staticmethod
    def mergeAllLogs():
        """This will merge all the logs found in /tmp/minindn/ and sort them by timestamp

        """
        #TODO: Delete any leading spaces to make sure all entries have timestamp at the beginning of the line!
        #TODO: Add node name after the timestamp when merging!

        info("Merging all logs!\n")

        directory_path = '/tmp/minindn'
        output_file_path = 'mergedLog.log'
        target_filename = 'nfd.log'
    
        lines = MergeNFDLogs.read_lines_from_directory(directory_path, target_filename)
        MergeNFDLogs.write_sorted_lines_to_file(lines, output_file_path)
        print(f"Lines from {directory_path}/<all nodes>/log/nfd.log have been merged and sorted into {output_file_path}")

        # Count interest packets
        keyword1 = 'CABEEE'
        keyword2 = 'onIncomingInterest'
        count = MergeNFDLogs.count_specific_lines(output_file_path, keyword1, keyword2)
        print(f"\nNumber of generated interest packets by applications (onIncomingInterest to each node from applications): {count} interests\n")
        # Count data packets
        keyword1 = 'CABEEE'
        keyword2 = 'onOutgoingData'
        count = MergeNFDLogs.count_specific_lines(output_file_path, keyword1, keyword2)
        print(f"Number of received data packets by applications (onOutgoingData from each node to applications): {count} data\n")


        return None
