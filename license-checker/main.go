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
	"io/fs"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

const (
	goLicenseFile            = "/app/LICENSE-HEADER-GO.txt" // Change this to the path of your license file
	genericLicenseHeaderFile = "/app/LICENSE-HEADER-ALL.txt"
	shellLicenseHeaderFile   = "/app/LICENSE-HEADER-SHELL.txt"
	rootDir                  = "." // Change this to the directory you want to search
	shellExtensions          = ".sh"
	yamlExtensions           = ".yaml"
	dockerExtensions         = "Dockerfile"
	goExtensions             = ".go"
)

func main() {
	isAutofixEnabled := flag.Bool("auto-fix", false, "Autofix enabled")
	flag.Parse()

	hasLicense, err := checkGoLicenseHeader(isAutofixEnabled)
	if err != nil {
		fmt.Println("Error checking go license header:", err)
	}
	hasLicense, err = checkShellLicenseHeader(isAutofixEnabled)
	if err != nil {
		fmt.Println("Error checking shell license header:", err)
	}
	hasLicense, err = checkYamlLicenseHeader(isAutofixEnabled)
	if err != nil {
		fmt.Println("Error checking YAML license header:", err)
	}
	hasLicense, err = checkDockerFileLicenseHeader(isAutofixEnabled)
	if err != nil {
		fmt.Println("Error checking Dockerfile license header:", err)
	}
	// if any of the license headers are missing or incorrect then exit with error
	if !hasLicense {
		os.Exit(1)
	}
}

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
	if err = scanner.Err(); err != nil {
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

func autofixLicenseHeader(filePath, licenseHeader string) error {
	input, err := os.ReadFile(filePath)
	if err != nil {
		return err
	}

	output := licenseHeader + "\n\n" + string(input)
	return os.WriteFile(filePath, []byte(output), 0644)
}

func checkGoLicenseHeader(isAutofixEnabled *bool) (bool, error) {
	licenseHeader, err := readLicenseHeader(goLicenseFile)
	if err != nil {
		fmt.Println("Error reading license file:", err)
		return false, err
	}
	files, err := listFilesByExtension(goExtensions)
	if err != nil {
		return false, err
	}
	fmt.Println("Checking license header for the following go files:")
	for _, file := range files {
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
				err = autofixLicenseHeader(file, licenseHeader)
				if err != nil {
					fmt.Printf("Error updating license header for file %s: %v\n", file, err)
				} else {
					fmt.Printf("License header updated for file: %s\n", file)
				}
			}
		}
	}
	return hasLicense, nil
}

func checkShellLicenseHeader(isAutofixEnabled *bool) (bool, error) {
	licenseHeader, err := readLicenseHeader(shellLicenseHeaderFile)
	if err != nil {
		fmt.Println("Error reading license file:", err)
		return false, err
	}
	files, err := listFilesByExtension(shellExtensions)
	if err != nil {
		return false, err
	}
	fmt.Println("Checking license header for the following shell script files:")
	for _, file := range files {
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
				err = autofixLicenseHeader(file, licenseHeader)
				if err != nil {
					fmt.Printf("Error updating license header for file %s: %v\n", file, err)
				} else {
					fmt.Printf("License header updated for file: %s\n", file)
				}
			}
		}
	}
	return hasLicense, nil
}

func checkDockerFileLicenseHeader(isAutofixEnabled *bool) (bool, error) {
	licenseHeader, err := readLicenseHeader(genericLicenseHeaderFile)
	if err != nil {
		fmt.Println("Error reading license file:", err)
		return false, err
	}
	files, err := listFilesByExtension(dockerExtensions)
	if err != nil {
		return false, err
	}
	fmt.Println("Checking license header for the following Docker files:")
	for _, file := range files {
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
				err = autofixLicenseHeader(file, licenseHeader)
				if err != nil {
					fmt.Printf("Error updating license header for file %s: %v\n", file, err)
				} else {
					fmt.Printf("License header updated for file: %s\n", file)
				}
			}
		}
	}
	return hasLicense, nil
}

func checkYamlLicenseHeader(isAutofixEnabled *bool) (bool, error) {
	licenseHeader, err := readLicenseHeader(genericLicenseHeaderFile)
	if err != nil {
		fmt.Println("Error reading license file:", err)
		return false, err
	}
	files, err := listFilesByExtension(yamlExtensions)
	if err != nil {
		return false, err
	}
	fmt.Println("Checking license header for the following YAML files:")
	for _, file := range files {
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
				err = autofixLicenseHeader(file, licenseHeader)
				if err != nil {
					fmt.Printf("Error updating license header for file %s: %v\n", file, err)
				} else {
					fmt.Printf("License header updated for file: %s\n", file)
				}
			}
		}
	}
	return hasLicense, nil
}

func listFilesByExtension(extension string) ([]string, error) {
	var files []string
	err := filepath.WalkDir(rootDir, func(path string, dirEntry fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		// we will check for generated and mock files for go extension only else search for other file types
		if extension == goExtensions {
			if !dirEntry.IsDir() &&
				strings.HasSuffix(dirEntry.Name(), extension) &&
				!strings.Contains(dirEntry.Name(), "mock") &&
				!strings.Contains(dirEntry.Name(), "generated") {
				files = append(files, path)
			}
		} else {
			if !dirEntry.IsDir() &&
				strings.HasSuffix(dirEntry.Name(), extension) {
				files = append(files, path)
			}
		}
		return nil
	})
	return files, err
}
