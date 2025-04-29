/*
 *
 * Copyright © 2025 Dell Inc. or its subsidiaries. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

func readLicenseHeader(filePath string) (string, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", err
	}
	defer file.Close()

	var headerLines []string
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		headerLines = append(headerLines, scanner.Text())
	}
	if err := scanner.Err(); err != nil {
		return "", err
	}
	return strings.Join(headerLines, "\n"), nil
}

func checkLicenseHeader(filePath, licenseHeader string) (bool, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return false, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	headerLines := strings.Split(licenseHeader, "\n")
	for i := 0; scanner.Scan() && i < len(headerLines); i++ {
		if !strings.Contains(headerLines[i], "Copyright") {
			if strings.TrimSpace(scanner.Text()) != strings.TrimSpace(headerLines[i]) {
				return false, nil
			}
		} else {
			// Check for the copyright year using regex
			re := regexp.MustCompile(`Copyright © \d{4}`)
			if !re.MatchString(scanner.Text()) {
				return false, nil
			}
		}
	}
	return true, scanner.Err()
}

func listGoFiles(root string) ([]string, error) {
	var files []string
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && strings.HasSuffix(info.Name(), ".go") && !strings.Contains(info.Name(), "mock") && !strings.Contains(info.Name(), "generated") {
			files = append(files, path)
		}
		return nil
	})
	return files, err
}
func autofixLicenseHeader(filePath, licenseHeader string) error {
	input, err := os.ReadFile(filePath)
	if err != nil {
		return err
	}

	output := licenseHeader + "\n\n" + string(input)
	return os.WriteFile(filePath, []byte(output), 0644)
}

func main() {
	isAutofixEnabled := flag.Bool("auto-fix", false, "Autofix enabled")
	flag.Parse()

	licenseFile := "/app/LICENSE-HEADER.txt" // Change this to the path of your license file

	licenseHeader, err := readLicenseHeader(licenseFile)
	if err != nil {
		fmt.Println("Error reading license file:", err)
		return
	}

	root := "." // Change this to the directory you want to search
	files, err := listGoFiles(root)
	if err != nil {
		fmt.Println("Error:", err)
		return
	}
	for _, file := range files {
		fmt.Println("Checking license header for the following files:")
		fmt.Println(file)
	}
	var hasLicense bool
	for _, file := range files {
		hasLicense, err = checkLicenseHeader(file, licenseHeader)
		if err != nil {
			fmt.Printf("Error checking file %s: %v\n", file, err)
			continue
		}
		if !hasLicense {
			fmt.Printf("Missing or incorrect license header: %s\n", file)
			//  if auto-fix is enabled then only we will fix the license headers else just report valid header and exit
			if *isAutofixEnabled {
				err := autofixLicenseHeader(file, licenseHeader)
				if err != nil {
					fmt.Printf("Error updating license header for file %s: %v\n", file, err)
				} else {
					fmt.Printf("License header updated for file: %s\n", file)
				}
			}
		}
	}
	if !hasLicense {
		os.Exit(1)
	}
}
