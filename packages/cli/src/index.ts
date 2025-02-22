// Copyright (c) Microsoft Corporation.
// Licensed under the MIT license.

"use strict";

import { initializePreviewFeatureFlags } from "@microsoft/teamsfx-core";
import fs from "fs-extra";
import * as path from "path";
import { start as startNewUX } from "./commands/index";
import { logger } from "./commonlib/logger";
import { CliTelemetryReporter } from "./commonlib/telemetry";
import "./console/screen";
import * as constants from "./constants";
import cliTelemetry from "./telemetry/cliTelemetry";
import { TelemetryProperty } from "./telemetry/cliTelemetryEvents";

initializePreviewFeatureFlags();

export function initTelemetryReporter(): void {
  const cliPackage = JSON.parse(fs.readFileSync(path.join(__dirname, "/../package.json"), "utf8"));
  const reporter = new CliTelemetryReporter(
    cliPackage.aiKey,
    constants.cliTelemetryPrefix,
    cliPackage.version
  );
  cliTelemetry.reporter = reporter;
}

/**
 * Starts the CLI process.
 */
export async function start(binName: "teamsfx" | "teamsapp"): Promise<void> {
  initTelemetryReporter();
  if (binName === "teamsfx") {
    logger.warning(
      "Warning: We are planning to depreate 'teamsfx' as command signagure and move to 'teamsapp' instead in the next major version of Teams Toolkit CLI."
    );
  }
  cliTelemetry.reporter?.addSharedProperty(TelemetryProperty.BinName, binName); // trigger binary name for telemetry
  return startNewUX(binName);
}
