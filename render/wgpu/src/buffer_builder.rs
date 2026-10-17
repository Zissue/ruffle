use bytemuck::{AnyBitPattern, NoUninit};
use std::ops::Range;

pub struct BufferBuilder {
    inner: Vec<u8>,
    align_mask: usize,
    limit: u64,
}

#[derive(Debug, Copy, Clone)]
pub struct BufferFull;

impl BufferBuilder {
    pub fn new(limits: &wgpu::Limits, alignment: u32) -> Self {
        Self {
            inner: Vec::new(),
            align_mask: if alignment > 0 {
                assert!(alignment.is_power_of_two());
                (alignment - 1) as usize
            } else {
                0
            },
            limit: limits.max_buffer_size,
        }
    }

    pub fn add<T: NoUninit + AnyBitPattern>(
        &mut self,
        value: &[T],
    ) -> Result<Range<wgpu::BufferAddress>, BufferFull> {
        // Pad on creation so that we don't wastefully pad the end of the buffer
        let start_pos = if self.align_mask > 0 {
            (self.inner.len() + self.align_mask) & !self.align_mask
        } else {
            self.inner.len().next_multiple_of(size_of::<T>())
        };

        let slice = bytemuck::cast_slice(value);
        if (start_pos + slice.len()) as u64 > self.limit {
            return Err(BufferFull);
        }

        self.inner.resize(start_pos, 0);

        self.inner.extend_from_slice(slice);
        Ok((start_pos as wgpu::BufferAddress)..(self.inner.len() as wgpu::BufferAddress))
    }

    pub fn bytes(&self) -> &[u8] {
        &self.inner
    }

    pub fn bytes_mut(&mut self) -> &mut [u8] {
        &mut self.inner
    }
}
