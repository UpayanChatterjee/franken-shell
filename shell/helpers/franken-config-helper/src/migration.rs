use thiserror::Error;

use crate::schema::{CURRENT_SCHEMA_VERSION, Configuration};

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct MigrationOutcome {
    pub effective_version: u32,
    pub occurred: bool,
}

#[derive(Clone, Copy)]
struct Migration {
    from: u32,
    to: u32,
    apply: fn(&mut Configuration),
}

#[derive(Debug, Error, Eq, PartialEq)]
pub enum MigrationError {
    #[error("no sequential migration is available from schema version {0}")]
    MissingStep(u32),
}

const MIGRATIONS: &[Migration] = &[Migration {
    from: 0,
    to: 1,
    apply: migrate_zero_to_one,
}];

pub fn migrate(
    configuration: &mut Configuration,
    source_version: u32,
) -> Result<MigrationOutcome, MigrationError> {
    let mut effective_version = source_version;
    let mut occurred = false;

    while effective_version < CURRENT_SCHEMA_VERSION {
        let Some(step) = MIGRATIONS
            .iter()
            .find(|step| step.from == effective_version)
        else {
            return Err(MigrationError::MissingStep(effective_version));
        };

        (step.apply)(configuration);
        effective_version = step.to;
        debug_assert_eq!(configuration.schema_version, effective_version);
        occurred = true;
    }

    Ok(MigrationOutcome {
        effective_version,
        occurred,
    })
}

fn migrate_zero_to_one(configuration: &mut Configuration) {
    // Schema 0 is retained only as the fixture predecessor for the sequential
    // migration boundary. Its supported fields already map to the schema-one
    // normalized model, so the in-memory transform advances the version.
    configuration.schema_version = 1;
}

#[cfg(test)]
mod tests {
    use crate::schema::Configuration;

    use super::{MigrationError, migrate};

    #[test]
    fn migrates_sequentially_from_zero_to_one() {
        let mut configuration = Configuration {
            schema_version: 0,
            ..Configuration::default()
        };
        let outcome = migrate(&mut configuration, 0).expect("migration should exist");
        assert_eq!(outcome.effective_version, 1);
        assert!(outcome.occurred);
        assert_eq!(configuration.schema_version, 1);
    }

    #[test]
    fn current_schema_does_not_migrate() {
        let mut configuration = Configuration::default();
        let outcome = migrate(&mut configuration, 1).expect("current schema should pass through");
        assert_eq!(outcome.effective_version, 1);
        assert!(!outcome.occurred);
        assert_eq!(configuration.schema_version, 1);
    }

    #[test]
    fn missing_step_is_structured() {
        assert_eq!(
            MigrationError::MissingStep(7).to_string(),
            "no sequential migration is available from schema version 7"
        );
    }
}
