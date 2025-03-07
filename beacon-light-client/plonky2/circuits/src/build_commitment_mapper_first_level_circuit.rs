use itertools::Itertools;
use plonky2::{
    field::{goldilocks_field::GoldilocksField, types::Field64},
    hash::hash_types::HashOutTarget,
    iop::target::BoolTarget,
    plonk::{
        circuit_builder::CircuitBuilder,
        circuit_data::CircuitConfig,
        config::{GenericConfig, PoseidonGoldilocksConfig},
        proof::{ProofWithPublicInputs, ProofWithPublicInputsTarget},
    },
};

use crate::{
    utils::{ETH_SHA256_BIT_SIZE, POSEIDON_HASH_SIZE},
    validator_commitment_mapper::{validator_commitment_mapper, ValidatorCommitmentTargets},
};

pub const POSEIDON_HASH_PUB_INDEX: usize = 0;
pub const SHA256_HASH_PUB_INDEX: usize = 4;

pub type CommitmentMapperProof =
    ProofWithPublicInputs<GoldilocksField, PoseidonGoldilocksConfig, 2>;

pub trait CommitmentMapperProofExt {
    fn get_commitment_mapper_poseidon_hash_tree_root(&self) -> Vec<u64>;

    fn get_commitment_mapper_sha256_hash_tree_root(&self) -> Vec<u64>;
}

impl CommitmentMapperProofExt for CommitmentMapperProof {
    fn get_commitment_mapper_poseidon_hash_tree_root(&self) -> Vec<u64> {
        return self.public_inputs
            [POSEIDON_HASH_PUB_INDEX..POSEIDON_HASH_PUB_INDEX + POSEIDON_HASH_SIZE]
            .iter()
            .map(|x| x.0 % GoldilocksField::ORDER)
            .collect_vec();
    }

    fn get_commitment_mapper_sha256_hash_tree_root(&self) -> Vec<u64> {
        return self.public_inputs
            [SHA256_HASH_PUB_INDEX..SHA256_HASH_PUB_INDEX + ETH_SHA256_BIT_SIZE]
            .iter()
            .map(|x| x.0 % GoldilocksField::ORDER)
            .collect_vec();
    }
}

pub type CommitmentMapperProofTarget = ProofWithPublicInputsTarget<2>;

pub trait CommitmentMapperProofTargetExt {
    fn get_commitment_mapper_poseidon_hash_tree_root(&self) -> HashOutTarget;

    fn get_commitment_mapper_sha256_hash_tree_root(&self) -> [BoolTarget; ETH_SHA256_BIT_SIZE];
}

impl CommitmentMapperProofTargetExt for CommitmentMapperProofTarget {
    fn get_commitment_mapper_poseidon_hash_tree_root(&self) -> HashOutTarget {
        HashOutTarget {
            elements: self.public_inputs
                [POSEIDON_HASH_PUB_INDEX..POSEIDON_HASH_PUB_INDEX + POSEIDON_HASH_SIZE]
                .try_into()
                .unwrap(),
        }
    }

    fn get_commitment_mapper_sha256_hash_tree_root(&self) -> [BoolTarget; ETH_SHA256_BIT_SIZE] {
        self.public_inputs[SHA256_HASH_PUB_INDEX..SHA256_HASH_PUB_INDEX + ETH_SHA256_BIT_SIZE]
            .iter()
            .cloned()
            .map(|x| BoolTarget::new_unsafe(x))
            .collect_vec()
            .try_into()
            .unwrap()
    }
}

pub fn build_commitment_mapper_first_level_circuit() -> (
    ValidatorCommitmentTargets,
    plonky2::plonk::circuit_data::CircuitData<
        plonky2::field::goldilocks_field::GoldilocksField,
        PoseidonGoldilocksConfig,
        2,
    >,
) {
    const D: usize = 2;
    type C = PoseidonGoldilocksConfig;
    type F = <C as GenericConfig<D>>::F;

    let standard_recursion_config = CircuitConfig::standard_recursion_config();

    let mut builder = CircuitBuilder::<F, D>::new(standard_recursion_config);

    let validator_commitment_result = validator_commitment_mapper(&mut builder);

    builder.register_public_inputs(&validator_commitment_result.poseidon_hash_tree_root.elements);
    builder.register_public_inputs(
        &validator_commitment_result
            .sha256_hash_tree_root
            .map(|x| x.target),
    );

    let data = builder.build::<C>();

    (validator_commitment_result, data)
}

#[cfg(test)]
mod test {
    use anyhow::Result;
    use plonky2::iop::witness::{PartialWitness, WitnessWrite};

    use crate::{
        build_commitment_mapper_first_level_circuit::build_commitment_mapper_first_level_circuit,
        utils::ETH_SHA256_BIT_SIZE,
    };

    #[test]
    fn test_validator_hash_tree_root() -> Result<()> {
        let (validator_commitment, data) = build_commitment_mapper_first_level_circuit();

        let mut pw = PartialWitness::new();

        let validator_pubkey = [
            "1", "0", "0", "1", "0", "0", "1", "1", "0", "0", "1", "1", "1", "0", "1", "0", "1",
            "1", "0", "1", "1", "0", "0", "1", "0", "1", "0", "0", "1", "0", "0", "1", "0", "0",
            "0", "1", "1", "0", "1", "1", "0", "1", "1", "0", "0", "0", "1", "0", "0", "0", "0",
            "0", "0", "1", "0", "1", "1", "0", "0", "1", "1", "1", "0", "1", "1", "1", "0", "1",
            "0", "0", "0", "0", "0", "1", "1", "0", "0", "1", "0", "1", "1", "0", "1", "1", "0",
            "1", "0", "1", "0", "1", "1", "0", "0", "0", "0", "0", "1", "1", "0", "1", "0", "0",
            "1", "0", "0", "1", "0", "1", "0", "1", "1", "0", "1", "1", "0", "1", "1", "0", "0",
            "0", "1", "0", "0", "1", "0", "1", "0", "1", "0", "1", "1", "1", "1", "0", "1", "0",
            "1", "0", "0", "0", "1", "1", "0", "0", "0", "1", "0", "0", "0", "0", "0", "0", "0",
            "0", "1", "0", "1", "1", "0", "0", "1", "1", "0", "0", "0", "1", "1", "0", "1", "1",
            "1", "0", "1", "0", "0", "0", "1", "1", "0", "1", "1", "0", "0", "0", "1", "1", "1",
            "0", "1", "1", "1", "0", "0", "1", "1", "1", "0", "0", "1", "0", "1", "0", "0", "1",
            "0", "0", "0", "0", "1", "0", "1", "0", "1", "1", "1", "0", "0", "0", "0", "1", "0",
            "0", "0", "1", "1", "1", "1", "0", "1", "0", "0", "0", "1", "1", "1", "1", "0", "1",
            "1", "1", "0", "0", "1", "1", "0", "0", "1", "0", "1", "0", "0", "1", "0", "0", "1",
            "0", "0", "1", "1", "0", "0", "1", "1", "1", "1", "0", "1", "0", "1", "0", "0", "0",
            "1", "0", "0", "0", "0", "0", "0", "1", "0", "0", "0", "1", "1", "1", "0", "0", "0",
            "0", "1", "1", "1", "0", "0", "1", "0", "1", "1", "1", "0", "1", "0", "1", "0", "0",
            "1", "0", "1", "0", "0", "1", "1", "1", "0", "1", "1", "0", "1", "0", "1", "1", "0",
            "0", "0", "1", "0", "1", "0", "0", "1", "0", "1", "0", "1", "0", "1", "1", "1", "0",
            "0", "0", "0", "1", "0", "0", "1", "1", "0", "1", "0", "0", "0", "0", "1", "0", "1",
            "0", "1", "1", "1", "0", "1", "0", "0", "1", "0", "1", "1", "0", "0", "0", "1", "1",
            "0", "0", "1", "0", "0", "1", "0", "1", "0", "1",
        ];

        let withdraw_credentials = [
            "0", "0", "0", "0", "0", "0", "0", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "1", "1",
            "0", "1", "0", "0", "1", "1", "0", "1", "1", "0", "1", "0", "0", "1", "1", "0", "1",
            "1", "1", "0", "1", "1", "0", "1", "0", "0", "1", "0", "0", "1", "1", "1", "1", "0",
            "1", "1", "1", "1", "1", "0", "1", "0", "0", "1", "0", "1", "0", "0", "0", "1", "0",
            "0", "0", "0", "0", "0", "0", "0", "1", "1", "1", "1", "1", "1", "0", "1", "0", "0",
            "1", "1", "1", "0", "1", "1", "1", "0", "0", "0", "0", "1", "1", "0", "1", "0", "1",
            "0", "1", "0", "0", "1", "1", "1", "1", "1", "1", "0", "0", "0", "0", "0", "1", "0",
            "1", "0", "0", "0", "1", "1", "0", "0", "0", "1", "0", "1", "0", "1", "0", "1", "1",
            "1", "0", "1", "1", "0", "1", "0", "0", "0", "0", "0", "0", "1", "0", "0", "1", "1",
            "0", "1", "0", "0", "1", "0", "1", "1", "0", "1", "0", "1", "0", "1", "0", "0", "0",
            "0",
        ];

        let effective_balance = [
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "1", "0", "0", "0", "0", "0", "0", "0",
            "1", "0", "1", "1", "0", "0", "1", "0", "1", "1", "1", "0", "0", "1", "1", "0", "0",
            "0", "0", "0", "1", "1", "1", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0",
        ];

        let slashed = [
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0",
        ];

        let activation_eligibility_epoch = [
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0",
        ];

        let withdrawable_epoch = [
            "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1",
            "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1",
            "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1",
            "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "1", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0", "0",
            "0",
        ];

        let validator_hash_tree_root = [
            "0", "0", "1", "0", "1", "0", "1", "1", "1", "0", "1", "0", "1", "1", "1", "1", "0",
            "1", "0", "0", "0", "0", "0", "0", "0", "1", "1", "0", "0", "1", "0", "1", "1", "0",
            "1", "1", "0", "1", "0", "1", "1", "1", "0", "1", "0", "1", "1", "0", "0", "0", "1",
            "0", "0", "1", "0", "0", "0", "1", "1", "0", "0", "1", "0", "0", "0", "0", "0", "1",
            "0", "0", "0", "0", "0", "1", "0", "1", "0", "0", "0", "1", "1", "0", "0", "0", "1",
            "1", "0", "0", "0", "1", "1", "1", "1", "0", "0", "1", "1", "0", "0", "0", "0", "0",
            "0", "1", "1", "1", "1", "0", "0", "1", "0", "1", "0", "1", "0", "1", "0", "0", "0",
            "0", "0", "1", "1", "1", "1", "1", "0", "0", "1", "1", "1", "0", "1", "0", "0", "0",
            "0", "0", "1", "0", "1", "1", "0", "1", "0", "1", "0", "0", "0", "1", "1", "0", "1",
            "1", "0", "1", "1", "0", "0", "0", "0", "1", "1", "1", "1", "1", "1", "1", "1", "0",
            "0", "0", "0", "0", "0", "0", "1", "0", "0", "1", "1", "0", "0", "1", "1", "1", "0",
            "1", "1", "1", "1", "1", "0", "1", "0", "1", "0", "0", "1", "0", "1", "1", "0", "0",
            "0", "0", "1", "1", "1", "0", "0", "1", "0", "1", "1", "0", "1", "1", "0", "0", "0",
            "0", "1", "1", "1", "0", "1", "1", "0", "1", "1", "0", "0", "0", "1", "0", "1", "0",
            "1", "1", "0", "0", "0", "0", "1", "1", "1", "1", "1", "1", "0", "1", "0", "1", "0",
            "1",
        ];

        for i in 0..384 {
            pw.set_bool_target(
                validator_commitment.validator.pubkey[i],
                validator_pubkey[i] == "1",
            );
        }

        for i in 0..ETH_SHA256_BIT_SIZE {
            pw.set_bool_target(
                validator_commitment.validator.withdrawal_credentials[i],
                withdraw_credentials[i] == "1",
            );

            pw.set_bool_target(
                validator_commitment.validator.effective_balance[i],
                effective_balance[i] == "1",
            );

            pw.set_bool_target(validator_commitment.validator.slashed[i], slashed[i] == "1");

            pw.set_bool_target(
                validator_commitment.validator.activation_eligibility_epoch[i],
                activation_eligibility_epoch[i] == "1",
            );

            pw.set_bool_target(validator_commitment.validator.activation_epoch[i], false);

            pw.set_bool_target(
                validator_commitment.validator.exit_epoch[i],
                if i < 64 { true } else { false },
            );

            pw.set_bool_target(
                validator_commitment.validator.withdrawable_epoch[i],
                withdrawable_epoch[i] == "1",
            );
        }

        let proof = data.prove(pw).unwrap();

        for i in 0..ETH_SHA256_BIT_SIZE {
            assert_eq!(
                proof.public_inputs[i + 4].to_string(),
                validator_hash_tree_root[i].to_string()
            )
        }

        Ok(())
    }
}
