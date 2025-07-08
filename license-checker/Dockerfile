# Copyright © 2020-2025 Dell Inc. or its subsidiaries. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#      http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

FROM golang:1.24

LABEL "com.github.actions.name"="license-checker"
LABEL "com.github.actions.description"="Checks for license header"
LABEL "com.github.actions.icon"="eye"
LABEL "com.github.actions.color"="gray-dark"

LABEL version="1.0.0"

WORKDIR /app

COPY go.mod go.sum main.go LICENSE-HEADER-GO.txt LICENSE-HEADER-SHELL.txt LICENSE-HEADER-ALL.txt ./
RUN go build .

ENTRYPOINT ["/app/license-checker"]
